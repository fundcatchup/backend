use anyhow::Context;

// STORE_PID environment variable must be set for this to run
pub fn store_pid(home: String) -> anyhow::Result<()> {
    if std::env::var("STORE_PID").is_err() {
        return Ok(());
    }

    let _ = std::fs::create_dir(home.clone());
    let _ = std::fs::remove_file(format!("{}/pid", home));
    std::fs::write(format!("{}/pid", home), std::process::id().to_string())
        .context("Writing PID file")?;
    Ok(())
}
