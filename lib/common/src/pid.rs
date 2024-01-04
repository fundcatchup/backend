use anyhow::Context;

pub fn store_pid(home: String) -> anyhow::Result<()> {
    let _ = std::fs::create_dir(home.clone());
    let _ = std::fs::remove_file(format!("{}/pid", home));
    std::fs::write(format!("{}/pid", home), std::process::id().to_string())
        .context("Writing PID file")?;
    Ok(())
}
