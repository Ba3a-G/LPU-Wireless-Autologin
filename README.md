

A simple script to automate the login process of LPU Networks.

And no, you don't have to use Selenium like a frigging noob. This script uses `curl` to send the login request to the server, which makes it _blazingly_ fast. It's so fast that you can't even see the login page. At this point you might be wondering, "Then how do I logout?". Well, you can't. But you can always restart your computer, which is also pretty good. No, just kidding. You can always logout by going to the login page and clicking on the logout button. It's not that hard.

Why am I writing nonsense here even though I have Computer Organisation and Design exam tomorrow? Because I am an idiot. ~~I am going to fail anyway.~~ I passed. 🥳 So, why not write some nonsense? I am not even sure if anyone is going to read this. If you are reading this, then you are an idiot too. Just kidding. You are a genius. Now star this repo and follow me on [LinkedIn](https://linkedin.com/in/ba3a). And also on GitHub.


## Features

- Multi-account support: Store and manage credentials for multiple LPU WiFi accounts using unique identifiers.
- Command-line options: Access various functionalities through command-line options, such as displaying help, version information, listing stored accounts, and logging in to a specific account.
- Secure credential storage: Credentials are stored securely in a separate file (`~/.lpu_creds`) instead of being directly added to the shell configuration files or `.profile`.
- Shell configuration updates: The script automatically updates the shell configuration files to source the credential file, ensuring seamless integration with the current shell session.

## Usage

1. Run the script without any arguments to prompt for an account ID and log in:

```bash
chmod +x main.sh
./main.sh
```

2. Use the available command-line options:

- `--help`: Display help information and usage instructions.
- `--version`: Show the version information.
- `--list`: List all stored account IDs.
- `--account <account_id>`: Log in using the specified account ID.
  Example:

```bash
./main.sh --account myaccount
```

3. If you don't have any stored credentials, the script will prompt you to enter a new account ID and the corresponding LPU username and password. These credentials will be securely stored for future use.
4. The script will attempt to log you into the LPU WiFi using the provided or stored credentials. A notification will be displayed indicating the login status (success or failure).

> Note: This script is designed to work with bash, zsh, and fish shells. If you are using a different shell, you may need to manually set the environment variables or update the shell configuration file.

You can also create an alias for the script in your `.bashrc` or other shell `.config` file to make it even simpler.

```bash
alias llogin="bash ~/path/to/main.sh"
```

Now you just have to type `llogin` in your terminal to login to the network.
And you can also use the different arguments along with the alias.

## To Do

1. [ ] Similar script for Windows
2. [x] Store credentials in env
3. [x] Multi account support (for people like [@saddexed](https://github.com/saddexed))
4. [ ] ~~Automation using nmcli dispatcher script~~

## Contributing

Pull requests are always welcome. Feel free to add any new features or fix any bugs you find.

```js
var foo = "bar";
```
