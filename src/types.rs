use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct Account {
    pub uid: String,
    pub pwd: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct LloginConfiguration {
    pub version: Option<String>,
    pub telemetry: Option<bool>,
    pub manifest: Option<String>,
    pub update_url: Option<String>,
    pub last_updated: Option<String>,
    pub error_count: Option<u32>,
    pub accounts: Vec<Account>,
}

impl LloginConfiguration {
    pub fn default() -> Self {
        LloginConfiguration {
            version: Some("2.0.1".to_string()),
            telemetry: Some(true),
            manifest: Some("default_manifest".to_string()),
            update_url: Some("https://github.com".to_string()),
            last_updated: Some("1973-01-01".to_string()),
            error_count: Some(0),
            accounts: vec![],
        }
    }
}