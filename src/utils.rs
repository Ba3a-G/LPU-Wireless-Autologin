use dirs;
use std::fs;
use crate::types::LloginConfiguration;

pub fn get_config_path() -> Result<std::path::PathBuf, Box<dyn std::error::Error>> {
    let home_dir = dirs::home_dir().ok_or("Cannot find home directory")?;
    let config_dir = home_dir.join(".config").join("llogin");
    let config_path = config_dir.join("config.toml");
    Ok(config_path)
}

// Write config with restricted permissions so other users can't read credentials.
// Permissions are tightened BEFORE writing so credentials never land on disk at
// loose permissions, even when upgrading from an older version that wrote 0644.
fn write_config_file(path: &std::path::Path, content: &str) -> Result<(), Box<dyn std::error::Error>> {
    #[cfg(unix)]
    {
        use std::io::Write;
        use std::os::unix::fs::{OpenOptionsExt, PermissionsExt};
        // Tighten permissions on existing files before truncating so the write lands
        // at 0600 from the start. mode(0o600) on OpenOptions only applies at creation.
        // Ignore NotFound: file may have been deleted between exists() and here;
        // the create(true) below handles that case at 0o600.
        if path.exists() {
            if let Err(e) = fs::set_permissions(path, fs::Permissions::from_mode(0o600)) {
                if e.kind() != std::io::ErrorKind::NotFound {
                    return Err(e.into());
                }
            }
        }
        let mut file = fs::OpenOptions::new()
            .write(true)
            .create(true)
            .truncate(true)
            .mode(0o600)
            .open(path)?;
        file.write_all(content.as_bytes())?;
        return Ok(());
    }
    #[cfg(not(unix))]
    {
        fs::write(path, content)?;
        Ok(())
    }
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
    write_config_file(&config_path, &config_content)?;
    Ok(())
}

pub fn get_platform_config() -> Result<LloginConfiguration, Box<dyn std::error::Error>> {
    let config_path = get_config_path()?;

    if !config_path.exists() {
        eprintln!("Config file does not exist. Creating a new one.");
        create_default_config()?;
        return Ok(LloginConfiguration::default());
    }

    let config_content = fs::read_to_string(&config_path)?;

    match toml::from_str(&config_content) {
        Ok(config) => Ok(config),
        Err(_) => {
            eprintln!("Config file seems to be corrupted. Creating a new one.");
            // Back up the corrupt file so the user can recover data.
            let backup_path = config_path.with_extension("toml.bak");
            if fs::copy(&config_path, &backup_path).is_ok() {
                // Restrict backup permissions — it contains the same credentials.
                #[cfg(unix)]
                {
                    use std::os::unix::fs::PermissionsExt;
                    let _ = fs::set_permissions(&backup_path, fs::Permissions::from_mode(0o600));
                }
                eprintln!("Corrupt config backed up to: {}", backup_path.display());
            }
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
            fs::create_dir_all(parent)?;
        }
    }
    write_config_file(&config_path, &config_content)?;
    Ok(())
}

pub fn login_to_wifi(uid: &str, pwd: &str) -> Result<(), Box<dyn std::error::Error>> {
    let username = format!("{}@lpu.com", uid);

    // LPU's captive portal uses a self-signed certificate; we accept it explicitly.
    // Traffic stays on the local network (10.10.0.1) so the MITM risk is limited.
    let connector = ureq::native_tls::TlsConnector::builder()
        .danger_accept_invalid_certs(true)
        .build()
        .map_err(|e| Box::new(e) as Box<dyn std::error::Error>)?;
    let client = ureq::AgentBuilder::new()
        .timeout(std::time::Duration::from_secs(10))
        .tls_connector(std::sync::Arc::new(connector))
        .build();

    // send_form encodes the body as application/x-www-form-urlencoded (spaces → +,
    // special chars → %XX), which is what the portal expects.
    let response = client
        .post("https://10.10.0.1/24online/servlet/E24onlineHTTPClient")
        .send_form(&[("mode", "191"), ("username", &username), ("password", pwd)]);

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
