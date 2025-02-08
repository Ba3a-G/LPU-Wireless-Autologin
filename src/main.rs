fn login_to_wifi(uid: &String, pwd: &String) -> Result<(), Box<dyn std::error::Error>> {
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

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 3 {
        eprintln!("Usage: {} <username> <password>", args[0]);
        std::process::exit(1);
    }
    let uid = &args[1];
    let pwd = &args[2];
    match login_to_wifi(uid, pwd) {
        Ok(_) => println!("Login successful"),
        Err(e) => eprintln!("Error: {}", e),
    }
}