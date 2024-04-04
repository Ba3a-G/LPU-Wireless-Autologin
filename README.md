# LLOGIN: Auto Login Script for LPU WiFi networks

A simple script to automate the login process of LPU Networks.

And no, you don't have to use Selenium like a frigging noob. This script uses `curl` to send the login request to the server, which makes it _blazingly_ fast. It's so fast that you can't even see the login page. At this point you might be wondering, "Then how do I logout?". Well, you can't. But you can always restart your computer, which is also pretty good. No, just kidding. You can always logout by going to the login page and clicking on the logout button. It's not that hard.

Why am I writing nonsense here even though I have Computer Organisation and Design exam tomorrow? Because I am an idiot. I am going to fail anyway. So, why not write some nonsense? I am not even sure if anyone is going to read this. If you are reading this, then you are an idiot too. Just kidding. You are a genius. Now star this repo and follow me on [LinkedIn](#). And also on GitHub.

## Usage

1. Run the script. It will first check if you are connected to LPU WiFi, if not, it will exit.

```bash
chmod +x main.sh
./main.sh
```

2. If you are connected to LPU WiFi, it will check if your LPU username and password are set. If not, it will prompt you to enter them. These credentials are stored securely in your `~/.profile` file.

3. Depending on the shell you are using (bash, zsh, or fish), it will add a line to source the `~/.profile` file in the appropriate shell configuration file (`~/.bashrc`, `~/.zshrc`, or `~/.config/fish/config.fish`).

4. Finally, it will attempt to log you into the LPU WiFi. If successful, it will display a notification saying "Login successful". If not, it will display a notification saying "Login failed".

> Note: This script is designed to work with bash, zsh, and fish shells. If you are using a different shell, you will need to manually set the `LPU_USERNAME` and `LPU_PASSWORD` environment variables in your shell configuration file.

You can also create an alias for the script in your `.bashrc` or other terminal `.config` file to make it even simpler.

```bash
alias llogin="bash ~/path/to/main.sh"
```

Now you just have to type `llogin` in your terminal to login to the network.

## To Do

1. Similar script for Windows
2. ~~Store credentials in env~~
3. Multi account support (for people like [@saddexed](https://github.com/saddexed))
4. Automation using nmcli dispatcher script.

## Contributing

Pull requests are always welcome. Feel free to add any new features or fix any bugs you find.

```js
var foo = "bar";
```
