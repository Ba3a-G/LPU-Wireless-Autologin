#!/bin/bash

# Check if you are connected to a LPU wifi
check_lpu_wifi() {
    if [ "$(nmcli -t -f active,ssid dev wifi | grep -E '^yes' | grep -c LPU)" == "1" ]; then
        return 0 
    else
        return 1 
    fi
}

# Reading and stroing the LPU credentials depending on the shell you are using
store_lpu_credentials() {
    read -p "Enter your LPU username: " username
    read -sp "Enter your LPU password: " password
    echo

    echo "LPU_USERNAME=\"$username\"" > ~/.profile
    echo "LPU_PASSWORD=\"$password\"" >> ~/.profile

    if [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ] || [ "$SHELL" = "bash" ]; then
        echo "source ~/.profile" >> ~/.bashrc
    elif [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ] || [ "$SHELL" = "zsh" ]; then
        echo "source ~/.profile" >> ~/.zshrc
    elif [ "$SHELL" = "/usr/bin/fish" ] || [ "$SHELL" = "/usr/bin/fish" ] || [ "$SHELL" = "fish" ]; then
      echo "set -gx LPU_USERNAME \"$username\"" >> ~/.config/fish/config.fish
      echo "set -gx LPU_PASSWORD \"$password\"" >> ~/.config/fish/config.fish   # who tf uses fish
    else
        echo "Unsupported shell. Please manually set the environment variables."
    fi

    echo "LPU username and password have been stored securely."
}

# Login to LPU wifi
perform_lpu_login() {
    username="$LPU_USERNAME"
    password="$LPU_PASSWORD"

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

    if [ -z "$LPU_USERNAME" ] || [ -z "$LPU_PASSWORD" ]; then
        echo "LPU username or password not set. Storing credentials."
        store_lpu_credentials
    fi
}

main  # Calling the main function

# Sourcing the shell configuration files
if [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ] || [ "$SHELL" = "bash" ]; then
    source ~/.bashrc
elif [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ] || [ "$SHELL" = "zsh" ]; then
    source ~/.zshrc
elif [ "$SHELL" = "/usr/bin/fish" ] || [ "$SHELL" = "/usr/bin/fish" ] || [ "$SHELL" = "fish" ]; then
    source ~/.config/fish/config.fish
fi

perform_lpu_login # Calling the login function
