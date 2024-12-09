#!/bin/bash
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
	local account_ids=$(env | grep LPU_USERNAME_ | cut -d'=' -f1 | cut -d'_' -f3)

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

	# Check if credentials already exist for the provided account ID
	if [ -n "${!username_var}" ] || [ -n "${!password_var}" ]; then
		echo "Credentials already exist for account ID '$account_id'."
		return
	fi

	read -p "Enter your LPU username: " username
	read -sp "Enter your LPU password: " password
	echo

	echo "export LPU_USERNAME_$account_id=\"$username\"" >>~/.lpu_creds
	echo "export LPU_PASSWORD_$account_id=\"$password\"" >>~/.lpu_creds

	# Update shell configuration files
	update_shell_config "$account_id" "$username" "$password"

	echo "LPU username and password have been stored securely. Reload the current shell or open a new one to use it :)" # TODO: make this automated.
}

update_shell_config() {
	local account_id="$1"
	local username="$2"
	local password="$3"

	local shell_config

	# NOTE: if u are using the xdg norm for your shell configs like me, you need to change the paths accordingly.
	if [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ] || [ "$SHELL" = "bash" ]; then
		shell_config="$HOME/.bashrc"
	elif [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ] || [ "$SHELL" = "zsh" ]; then
		shell_config="$HOME/.zshrc"
	elif [ "$SHELL" = "/usr/bin/fish" ] || [ "$SHELL" = "/usr/bin/fish" ] || [ "$SHELL" = "fish" ]; then
		shell_config="$HOME/.config/fish/config.fish"
	else
		echo "Unsupported shell. Please manually set the environment variables."
		return
	fi

	# Check if the source command already exists in the shell configuration file
	if ! grep -q "source ~/.lpu_creds" "$shell_config"; then
		echo "source ~/.lpu_creds" >>"$shell_config" #WARN: I know this won't work for fish but I hate the fish shell, so I'm just gonnna leave it like this idc ¯\_(ツ)_/¯ , maybe I'll fix it later (maybe).
		source "$shell_config"
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

main "$@" # Calling the main function
# TODO: replace if elses with switch statements
# Sourcing the shell configuration files
if [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ] || [ "$SHELL" = "bash" ]; then
	source ~/.bashrc
elif [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ] || [ "$SHELL" = "zsh" ]; then
	source ~/.zshrc
elif [ "$SHELL" = "/usr/bin/fish" ] || [ "$SHELL" = "/usr/bin/fish" ] || [ "$SHELL" = "fish" ]; then
	source ~/.config/fish/config.fish
fi
