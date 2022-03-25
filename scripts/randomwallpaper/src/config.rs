use anyhow::Context;
use std::path::Path;
use std::path::PathBuf;

pub struct Config {
    pub paths: Vec<PathBuf>,
    pub exclude: Vec<PathBuf>,
}

impl Config {
    pub fn new() -> anyhow::Result<Self> {
        Ok(Self {
            paths: vec![
                PathBuf::from("/usr/share/backgrounds"),
                Path::new(&std::env::var("HOME").context("couldn't get home directory")?)
                    .join(".local/share/backgrounds"),
            ],

            exclude: vec![PathBuf::from("/usr/share/backgrounds/xfce")],
        })
    }
}
