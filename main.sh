#!/bin/bash
# DEPRECATED: This bash script is the legacy implementation.
# Use the Rust CLI (llogin) instead: https://github.com/ba3a-g/LPU-Wireless-Autologin
# exec 19>logfile
# BASH_XTRACEFD=19    # uncomment to enable logging, because shell scripting is a pain
# set -x

show_help() {
	echo "Usage: $0 [OPTION] [ACCOUNT_ID]"
	echo "Manage and log in to multiple LPU WiFi accounts."
	echo
	echo "Options:"
	echo " --help       Show this help message and exit."
	echo " --version    Show version information and exit."
	echo " --list       List all stored account IDs."
}

show_version() {
	echo "LPU WiFi Manager 1.2" # hehe :)
}

prompt_for_account_id() {
	read -p "Enter the account ID or Name: " account_id
	main --account "$account_id"
}

# Function to list all stored account IDs
list_account_ids() {
	echo "Stored account IDs:"
	local account_ids
	# Read from the credentials file so fish users and fresh processes (cron,
	# systemd) see stored accounts even when ~/.lpu_creds has not been sourced.
	if [ -f ~/.lpu_creds ]; then
		account_ids=$(grep -oE 'LPU_USERNAME_[^=]+' ~/.lpu_creds | sed 's/LPU_USERNAME_//' | sort -u)
	fi
	# Also fall back to the environment for any accounts loaded in this session.
	local env_ids
	env_ids=$(env | grep '^LPU_USERNAME_' | cut -d'=' -f1 | sed 's/LPU_USERNAME_//' | sort -u)
	account_ids=$(printf '%s\n%s\n' "$account_ids" "$env_ids" | sort -u | grep -v '^$')

	if [ -z "$account_ids" ]; then
		echo "No stored account IDs found."
	else
		echo "$account_ids"
	fi
}

check_lpu_wifi() {
	if [ "$(nmcli -t -f active,ssid dev wifi | grep -E '^yes' | grep -Ecm 1 '^(LPU|Block)\s')" == "1" ]; then
		return 0
	else
		return 1
	fi
}

# Reading and storing the LPU credentials depending on the shell you are using
store_lpu_credentials() {
	read -p "Enter a unique identifier for this account: " account_id
	local username_var="LPU_USERNAME_$account_id"
	local password_var="LPU_PASSWORD_$account_id"

	# Check if credentials already exist for the provided account ID.
	# Check both the environment (if sourced) and the credentials files directly
	# so the guard works in fresh shells and cron jobs where the files haven't been sourced.
	if [ -n "${!username_var}" ] || [ -n "${!password_var}" ] \
		|| grep -qF "LPU_USERNAME_$account_id" ~/.lpu_creds 2>/dev/null \
		|| grep -qF "LPU_USERNAME_$account_id" ~/.lpu_creds.fish 2>/dev/null; then
		echo "Credentials already exist for account ID '$account_id'."
		return
	fi

	read -p "Enter your LPU username: " username
	read -sp "Enter your LPU password: " password
	echo

	# Always write bash-compatible export syntax. main.sh is #!/bin/bash and
	# perform_lpu_login reads credentials via ${!var} (bash indirect expansion),
	# so ~/.lpu_creds must be bash-sourceable regardless of the user's login shell.
	echo "export LPU_USERNAME_$account_id=\"$username\"" >>~/.lpu_creds
	echo "export LPU_PASSWORD_$account_id=\"$password\"" >>~/.lpu_creds
	chmod 600 ~/.lpu_creds

	# Export into the current bash process so perform_lpu_login can read them
	# immediately in the same session without waiting for a shell reload.
	export "LPU_USERNAME_$account_id=$username"
	export "LPU_PASSWORD_$account_id=$password"

	# Always write fish-syntax credentials regardless of $SHELL: $SHELL reflects
	# the login shell (/etc/passwd), not the currently active interactive shell.
	# Writing unconditionally ensures fish sessions work even when the user's
	# login shell is bash but they're running fish interactively.
	echo "set -gx LPU_USERNAME_$account_id \"$username\"" >>~/.lpu_creds.fish
	echo "set -gx LPU_PASSWORD_$account_id \"$password\"" >>~/.lpu_creds.fish
	chmod 600 ~/.lpu_creds.fish

	# Update shell configuration files
	update_shell_config "$account_id" "$username" "$password"

	echo "LPU username and password have been stored securely. Reload the current shell or open a new one to use it :)" # TODO: make this automated.
}

update_shell_config() {
	local account_id="$1"
	local username="$2"
	local password="$3"

	local shell_config
	local is_fish=false

	# NOTE: if u are using the xdg norm for your shell configs like me, you need to change the paths accordingly.
	if [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ] || [ "$SHELL" = "bash" ]; then
		shell_config="$HOME/.bashrc"
	elif [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ] || [ "$SHELL" = "zsh" ]; then
		shell_config="$HOME/.zshrc"
	elif [ "$SHELL" = "/bin/fish" ] || [ "$SHELL" = "/usr/bin/fish" ] || [ "$SHELL" = "fish" ]; then
		shell_config="$HOME/.config/fish/config.fish"
		is_fish=true
	else
		echo "Unsupported shell. Please manually set the environment variables."
		return
	fi

	# Check if the source command already exists in the shell configuration file
	if [ "$is_fish" = "true" ]; then
		# Remove stale lines written by older versions of this script (POSIX dot-source
		# and the old 'source ~/.lpu_creds' that pointed at bash-syntax credentials).
		# Use grep -v + temp file: portable across BSD sed (macOS) and GNU sed (Linux)
		# since 'sed -i' requires an explicit backup suffix on BSD.
		# Note: grep -v + || true so the mv always runs even when all lines matched
		# (grep -v exits 1 with empty output when every line matched the pattern).
		if grep -qE '^\. ~/\.lpu_creds$|^source ~/\.lpu_creds$' "$shell_config" 2>/dev/null; then
			local tmp_config
			tmp_config=$(mktemp) || { echo "Warning: cannot create temp file; skipping config cleanup."; return; }
			grep -vE '^\. ~/\.lpu_creds$|^source ~/\.lpu_creds$' "$shell_config" >"$tmp_config" 2>/dev/null || true
			mv "$tmp_config" "$shell_config" || rm -f "$tmp_config"
		fi
		# Fish reads fish-syntax credentials from a dedicated file.
		if ! grep -qF "source ~/.lpu_creds.fish" "$shell_config"; then
			echo "source ~/.lpu_creds.fish" >>"$shell_config"
		fi
	else
		# Migrate any stale fish-syntax (set -gx) lines that an older version of this
		# script may have written to ~/.lpu_creds. bash/zsh cannot parse them.
		if grep -qE '^set -gx ' ~/.lpu_creds 2>/dev/null; then
			local tmp_creds
			tmp_creds=$(mktemp) || true
			if [ -n "$tmp_creds" ]; then
				grep -E '^set -gx ' ~/.lpu_creds >>~/.lpu_creds.fish 2>/dev/null && chmod 600 ~/.lpu_creds.fish
				grep -vE '^set -gx ' ~/.lpu_creds >"$tmp_creds" 2>/dev/null || true
				mv "$tmp_creds" ~/.lpu_creds || rm -f "$tmp_creds"
				chmod 600 ~/.lpu_creds
			fi
		fi
		if ! grep -qF "source ~/.lpu_creds" "$shell_config"; then
			echo "source ~/.lpu_creds" >>"$shell_config"
			source "$shell_config"
		fi
	fi
}

# Login to LPU wifi
perform_lpu_login() {
	local account_id="$1"
	local username_var="LPU_USERNAME_$account_id"
	local password_var="LPU_PASSWORD_$account_id"
	local username="${!username_var}"
	local password="${!password_var}"
	# echo "$username"
	# echo "$password"

	data="mode=191&username=$username%40lpu.com&password=$password"
	res=$(curl -s 'https://10.10.0.1/24online/servlet/E24onlineHTTPClient' --data-raw $data --compressed --insecure)

	if [[ $res == *"To start surfing"* ]]; then # lmao
		echo "Login successful"
		notify-send "LPU Login" "Login successful" -i network-wireless
	else
		echo "Login failed"
		notify-send "LPU Login" "Login failed" -i network-error
	fi
}

# Main function
main() {
	if check_lpu_wifi; then
		echo "Connected to LPU WiFi"
	else
		echo "Not connected to LPU WiFi. Exiting."
		exit 1
	fi

	local option="$1"
	case $option in
	--help)
		show_help
		exit 0
		;;
	--version)
		show_version
		exit 0
		;;
	--account)
		if [ $# -eq 2 ]; then
			local account_id="$2"
			local username_var="LPU_USERNAME_$account_id"
			local password_var="LPU_PASSWORD_$account_id"

			if [ -z "${!username_var}" ] || [ -z "${!password_var}" ]; then
				echo "LPU username or password not set for account $account_id. Storing credentials."
				store_lpu_credentials
			fi

			perform_lpu_login "$account_id"
			exit 0
		else
			echo "Error: Please provide an account ID."
			exit 1
		fi
		;;
	--list)
		list_account_ids
		exit 0
		;;
	*)
		if [ $# -eq 0 ]; then
			echo "No account ID provided."
			prompt_for_account_id
			exit 0
		else
			echo "Error: Unknown option. Use --help for usage information."
			exit 1
		fi
		;;
	esac
}

main "$@"
