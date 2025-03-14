

A simple CLI app to automate the login process of LPU Networks.

And no, you don't have to use Selenium like a frigging noob. This app makes a `POST` request to the server, which makes it _blazingly_ fast. It's so fast that you can't even see the login page (lol). At this point you might be wondering, "Then how do I logout?". Well, you can't. But you can always restart your computer, which is also pretty good. No, just kidding. You can always logout by going to the login page and clicking on the logout button. It's not that hard.

Why am I writing nonsense here even though I have Computer Organisation and Design exam tomorrow? Because I am an idiot. ~~I am going to fail anyway.~~ I passed. 🥳 So, why not write some nonsense? I am not even sure if anyone is going to read this. If you are reading this, then you are an idiot too. Just kidding. You are a genius. Now star this repo and follow me on [LinkedIn](https://linkedin.com/in/ba3a). And also on GitHub.

> [!NOTE]  
> Use [main.sh](./main.sh) if you prefer the older bash script instead.

## Features

- Multi-account support: Store and manage credentials for multiple LPU WiFi accounts using unique identifiers.
- Command-line options: Access various functionalities through command-line options, such as displaying help, version information, listing stored accounts, and logging in to a specific account.
- Secure credential storage: Credentials are stored securely in a separate file `~/.config/llogin/config.toml` instead of being directly added to the shell configuration files or `.profile`.

## Installation

Use the installation script from [docs](./docs).
  - [Linux/Mac](./docs/install.sh)
  - [Windows](./docs/install.sh)

> [!WARNING]  
> Windows install script needs some more fixes cuz it is AI generated and I hate PSH/POSH (whatever). PRs welcome.

## Usage

0. `llogin -h` to see all available subcommands and flags.

1. Run the binary without any arguments to prompt for an account ID and log in. It will use the default account or ask you to choose, depending upon your config.

```bash
llogin
```

2. Use the available command-line options:

- `auth`: Use a particular account to login.
- `auto false/true`: Change default behavious between interactive and auto.
- `--help`: Display help information and usage instructions.
- `--version`: Show the version information.

  Example:

```bash
llogin auth 12218679
```

3. If you don't have any stored credentials, the script will prompt you to enter a new account ID and the corresponding LPU username and password. These credentials will be securely stored for future use.
4. The script will attempt to log you into the LPU WiFi using the provided or stored credentials. A notification will be displayed indicating the login status (success or failure).


## To Do

1. Auto upgrade (apparently in-place upgrade is trickier than I thought)
2. [ ] Support for missing architectures
3. [x] Multi account support (for people like [@saddexed](https://github.com/saddexed))
4. [ ] Automation for different platforms
    - It should be run automatically on network change. For example, nmcli dispatcher can be used on Linux.

## Contributing

Pull requests are always welcome. Feel free to add any new features or fix bugs you find.

```js
var foo = "bar";
```
