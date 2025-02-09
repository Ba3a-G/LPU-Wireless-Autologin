use clap::{Parser, Subcommand};
use requestty::Question;
use thiserror::Error;

mod types;
mod utils;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("Configuration error: {0}")]
    ConfigError(String),
    #[error("Authentication error: {0}")]
    AuthError(String),
    #[error("Input error: {0}")]
    InputError(String),
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),
}

type Result<T> = std::result::Result<T, AppError>;

#[derive(Parser)]
#[command(name = "llogin")]
#[command(author = "Aryan K")]
#[command(version = "2.0.1")]
#[command(about = "LPU WiFi manager")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
    /// If not set, I will use the first account in the list.
    #[arg(short, long, default_value = "false")]
    interactive: bool,
}

#[derive(Subcommand)]
enum Commands {
    /// Login to LPU WiFi
    Auth {
        /// User ID
        uid: String,
        /// Password (optional)
        password: Option<String>,
    },
    /// List all saved accounts
    List,
    /// Reorder accounts priority
    Reorder,
    /// Remove an account
    Remove {
        /// UID to remove
        username: Option<String>,
    },
    /// Update password for an account
    Update {
        /// User ID to update
        username: Option<String>,
    },
    /// Enable/disable telemetry
    Telemetry {
        /// Enable or disable telemetry
        enabled: Option<bool>,
    },
    /// Update the application
    Upgrade,
}

struct App {
    config: types::LloginConfiguration,
}

impl App {
    fn new() -> Result<Self> {
        let config =
            utils::get_platform_config().map_err(|e| AppError::ConfigError(e.to_string()))?;
        Ok(Self { config })
    }

    fn handle_auth(&mut self, uid: &String, password: Option<String>) -> Result<()> {
        let password = match password {
            Some(pwd) => pwd,
            None => self.get_or_prompt_password(uid)?,
        };

        utils::login_to_wifi(uid, &password).map_err(|e| AppError::AuthError(e.to_string()))?;

        println!("Logged in successfully");
        self.maybe_save_account(uid, &password)?;
        Ok(())
    }

    fn get_or_prompt_password(&self, uid: &str) -> Result<String> {
        if let Some(account) = self.config.accounts.iter().find(|a| a.uid == uid) {
            return Ok(account.pwd.clone());
        }

        let question = Question::password("Enter your password")
            .message("Enter your password")
            .build();

        requestty::prompt_one(question)
            .map_err(|e| AppError::InputError(e.to_string()))?
            .try_into_string()
            .map_err(|_| AppError::InputError("Invalid password input".into()))
    }

    fn maybe_save_account(&mut self, uid: &str, password: &str) -> Result<()> {
        if self.config.accounts.iter().any(|a| a.uid == uid) {
            return Ok(());
        }

        let question = Question::confirm("Do you want to save this account?")
            .message("Do you want to save this account?")
            .default(true)
            .build();

        let save = requestty::prompt_one(question)
            .map_err(|e| AppError::InputError(e.to_string()))?
            .try_into_bool()
            .map_err(|_| AppError::InputError("Invalid confirmation input".into()))?;

        if save {
            let new_account = types::Account {
                uid: uid.to_string(),
                pwd: password.to_string(),
            };
            self.config.accounts.push(new_account);
            utils::put_platform_config(&self.config)
                .map_err(|e| AppError::ConfigError(e.to_string()))?;
        }
        Ok(())
    }

    fn list_accounts(&self) {
        if self.config.accounts.is_empty() {
            println!("No saved accounts found");
            return;
        }

        println!("Saved accounts:");
        for account in &self.config.accounts {
            println!("{}", account.uid);
        }
    }

    fn remove_account(&mut self, username: Option<String>) -> Result<()> {
        let uid = match username {
            Some(uid) => uid,
            None => self.prompt_account_selection("Select account to remove")?,
        };

        if let Some(pos) = self.config.accounts.iter().position(|a| a.uid == uid) {
            self.config.accounts.remove(pos);
            utils::put_platform_config(&self.config)
                .map_err(|e| AppError::ConfigError(e.to_string()))?;
            println!("Account removed successfully");
        } else {
            println!("Account not found");
        }
        Ok(())
    }

    fn update_account(&mut self, username: Option<String>) -> Result<()> {
        let uid = match username {
            Some(uid) => uid,
            None => self.prompt_account_selection("Select account to update")?,
        };

        if !self.config.accounts.iter().any(|a| a.uid == uid) {
            println!("Account not found");
            return Ok(());
        }

        let question = Question::password("Enter your new password")
            .message("Enter your new password")
            .build();

        let new_password = requestty::prompt_one(question)
            .map_err(|e| AppError::InputError(e.to_string()))?
            .try_into_string()
            .map_err(|_| AppError::InputError("Invalid password input".into()))?;

        if let Some(account) = self.config.accounts.iter_mut().find(|a| a.uid == uid) {
            account.pwd = new_password;
            utils::put_platform_config(&self.config)
                .map_err(|e| AppError::ConfigError(e.to_string()))?;
            println!("Password updated successfully");
        }
        Ok(())
    }

    fn prompt_account_selection(&self, prompt: &str) -> Result<String> {
        let choices: Vec<String> = self.config.accounts.iter().map(|a| a.uid.clone()).collect();

        if choices.is_empty() {
            return Err(AppError::InputError("No accounts available".into()));
        }

        let question = Question::select("Select account")
            .message(prompt)
            .choices(choices)
            .build();

        let answer =
            requestty::prompt_one(question).map_err(|e| AppError::InputError(e.to_string()))?;

        answer
            .as_list_item()
            .map(|item| item.text.clone())
            .ok_or_else(|| AppError::InputError("Failed to parse account selection".into()))
    }

    fn reorder_account_priorities(&mut self) -> Result<()> {
        let choices: Vec<String> = self.config.accounts.iter().map(|a| a.uid.clone()).collect();

        if choices.is_empty() {
            return Err(AppError::InputError("No accounts available".into()));
        }

        let question = Question::order_select("accounts_priority")
            .message("Reorder accounts priority")
            .choices(choices)
            .build();
        let answer =
            requestty::prompt_one(question).map_err(|e| AppError::InputError(e.to_string()))?;
        let order = answer
            .as_list_items()
            .ok_or_else(|| AppError::InputError("Failed to parse account selection".into()))?;

        let mut new_accounts = Vec::new();
        for item in order {
            let uid = item.text.clone();

            // Find and remove the account from the current configuration
            let index = self
                .config
                .accounts
                .iter()
                .position(|a| a.uid == uid)
                .ok_or_else(|| AppError::InputError(format!("Account '{}' not found", uid)))?;
            let account = self.config.accounts.remove(index);
            new_accounts.push(account);
        }

        // Replace the accounts with the new ordered list
        self.config.accounts = new_accounts;

        utils::put_platform_config(&self.config)
            .map_err(|e| AppError::ConfigError(e.to_string()))?;

        Ok(())
    }

    fn set_telemetry(&mut self, enabled: Option<bool>) -> Result<()> {
        if let Some(_) = enabled {
            self.config.telemetry = enabled;
            utils::put_platform_config(&self.config)
                .map_err(|e| AppError::ConfigError(e.to_string()))?;
            println!("Telemetry settings updated");
        }
        Ok(())
    }

    fn handle_default(&mut self, is_interactive: bool) -> Result<()> {
        if self.config.accounts.is_empty() {
            println!("No saved accounts found. Please enter your credentials.");
            let uid = self.prompt_username()?;
            let password = self.get_or_prompt_password(&uid)?;
            return self.handle_auth(&uid, Some(password));
        }
    
        if !is_interactive {
            let account = &self.config.accounts[0];
            println!("Logging in with saved account: {}", account.uid);
            return self.handle_auth(&account.uid.clone(), Some(account.pwd.clone()));
        }
    
        let question = Question::select("account")
            .message("Choose an account to login with:")
            .choices(self.config.accounts.iter().map(|a| a.uid.clone()).collect::<Vec<_>>())
            .choice("Use a different account")
            .build();
    
        let answer = requestty::prompt_one(question)
            .map_err(|e| AppError::InputError(e.to_string()))?;
    
        let selected = answer.as_list_item()
            .ok_or_else(|| AppError::InputError("Invalid selection".into()))?
            .text.clone();
    
        if selected == "Use a different account" {
            let uid = self.prompt_username()?;
            let password = self.get_or_prompt_password(&uid)?;
            self.handle_auth(&uid, Some(password))
        } else {
            let account = self.config.accounts.iter()
                .find(|a| a.uid == selected)
                .ok_or_else(|| AppError::InputError("Selected account not found".into()))?;
            self.handle_auth(&account.uid.clone(), Some(account.pwd.clone()))
        }
    }
    
    fn prompt_username(&self) -> Result<String> {
        let question = Question::input("username")
            .message("Enter your username:")
            .build();
    
        requestty::prompt_one(question)
            .map_err(|e| AppError::InputError(e.to_string()))?
            .try_into_string()
            .map_err(|_| AppError::InputError("Invalid username input".into()))
    }
}

fn main() -> Result<()> {
    let mut app = App::new()?;
    let cli = Cli::parse();

    match cli.command {
        Some(Commands::Auth { uid, password }) => {
            app.handle_auth(&uid, password)?;
        }
        Some(Commands::List) => {
            app.list_accounts();
        }
        Some(Commands::Remove { username }) => {
            app.remove_account(username)?;
        }
        Some(Commands::Update { username }) => {
            app.update_account(username)?;
        }
        Some(Commands::Telemetry { enabled }) => {
            app.set_telemetry(enabled)?;
        }
        Some(Commands::Reorder) => {
            app.reorder_account_priorities()?;
        }
        Some(Commands::Upgrade) => {
            println!("Upgrade functionality not implemented yet");
        }
        None => {
            app.handle_default(cli.interactive)?;
        }
    }
    Ok(())
}
