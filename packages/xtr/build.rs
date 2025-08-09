use std::{fs, process::Command};

fn main() {
    let cargo_toml = fs::read_to_string("Cargo.toml").expect("Failed to read Cargo.toml");
    let cargo_toml: toml::Value = toml::from_str(&cargo_toml).expect("Failed to parse Cargo.toml");

    let crate_name = cargo_toml["package"]["name"].as_str().expect("Missing extra crate name");
    let crate_version = cargo_toml["package"]["version"].as_str().expect("Missing extra crate version");

    let crate_with_version = format!("{}@{}", crate_name, crate_version);

    let status = Command::new("cargo")
        .args(&[
            "install",
            &crate_with_version,
            "--root",
            "target/deps",
            "--locked",
        ])
        .status()
        .expect("Failed to run cargo install for extra crate");

    if !status.success() {
        panic!("cargo install for extra crate failed");
    }
}
