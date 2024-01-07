use std::{env, ffi::OsString};

fn get_env(key: &str) -> Option<OsString> {
    println!("cargo:rerun-if-env-changed={}", key);
    env::var_os(key)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("cargo:rerun-if-changed=migrations");

    let mut tonic = tonic_build::configure();

    // Buck likes to set $OUT in a genrule, while Cargo likes to set $OUT_DIR.
    // If we have $OUT set only, move it into the config
    if get_env("OUT_DIR").is_none() {
        if let Some(out) = get_env("OUT") {
            tonic = tonic.out_dir(out);
        }
    }

    tonic.compile(&["proto/api.proto"], &["proto"])?;

    Ok(())
}
