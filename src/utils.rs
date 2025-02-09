use dirs;
use std::fs;
use crate::types::LloginConfiguration;


pub fn get_config_path() -> Result<std::path::PathBuf, Box<dyn std::error::Error>> {
    let home_dir = dirs::home_dir().ok_or("Cannot find home directory")?;
    let config_dir = home_dir.join(".config").join("llogin");
    let config_path = config_dir.join("config.toml");
    Ok(config_path)
}

pub fn create_default_config() -> Result<(), Box<dyn std::error::Error>> {
    let config_path = get_config_path()?;
    let default_config = LloginConfiguration::default();
    let config_content = toml::to_string(&default_config)?;
    if let Some(parent) = config_path.parent() {
        if !parent.exists() {
            fs::create_dir_all(parent)?;
        }
    }
    fs::write(&config_path, config_content)?;
    Ok(())
}

pub fn get_platform_config() -> Result<LloginConfiguration, Box<dyn std::error::Error>> {
    let config_path = get_config_path()?;

    // Check if the configuration file exists
    if !config_path.exists() {
        eprintln!("Config file does not exist. Creating a new one.");
        create_default_config()?;
        return Ok(LloginConfiguration::default());
    }

    // Read the configuration file
    let config_content = fs::read_to_string(&config_path)?;

    // Parse the configuration file
    match toml::from_str(&config_content) {
        Ok(config) => Ok(config),
        Err(_) => {
            eprintln!("Config file seems to be corrupted. Creating a new one.");
            create_default_config()?;
            Ok(LloginConfiguration::default())
        }
    }
}

pub fn put_platform_config(config: &LloginConfiguration) -> Result<(), Box<dyn std::error::Error>> {
    let config_path = get_config_path()?;
    let config_content = toml::to_string(config)?;
    if let Some(parent) = config_path.parent() {
        if !parent.exists() {
            std::fs::create_dir_all(parent)?;
        }
    }
    std::fs::write(config_path, config_content)?;
    Ok(())
}

pub fn login_to_wifi(uid: &String, pwd: &String) -> Result<(), Box<dyn std::error::Error>> {
    let data = format!("mode=191&username={}%40lpu.com&password={}", uid, pwd);

    let client = ureq::AgentBuilder::new()
        .tls_connector(std::sync::Arc::new(
            ureq::native_tls::TlsConnector::builder()
                .danger_accept_invalid_certs(true)
                .build()
                .unwrap(),
        ))
        .build();

    let response = client
        .post("https://internet.lpu.in/24online/servlet/E24onlineHTTPClient")
        .set("Content-Type", "application/x-www-form-urlencoded")
        .send_string(&data);

    match response {
        Ok(res) => {
            let response_text = res.into_string()?;
            if response_text.contains("To start surfing") {
                return Ok(());
            } else if response_text.contains("Wrong username/password") {
                return Err(Box::new(std::io::Error::new(
                    std::io::ErrorKind::Other,
                    "Wrong username/password",
                )));
            } else {
                return Err(Box::new(std::io::Error::new(
                    std::io::ErrorKind::Other,
                    "Login failed",
                )));
            }
        }
        Err(e) => {
            eprintln!("Error: {}", e);
            return Err(Box::new(e));
        }
    }
}
