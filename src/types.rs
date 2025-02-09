use serde::{Deserialize, Serialize};

#[derive(Serialize)]
#[derive(Deserialize)]
pub struct Account {
    pub uid: String,
    pub pwd: String,
    pub is_default: bool,
}

#[derive(Serialize)]
#[derive(Deserialize)]
pub struct LloginConfiguration {
    pub telemetry: bool,
    pub last_updated: String,
    pub error_count: u32,
    pub accounts: Vec<Account>,
}