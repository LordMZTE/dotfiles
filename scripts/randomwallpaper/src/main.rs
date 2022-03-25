use anyhow::Context;
use config::Config;
use rand::prelude::{IteratorRandom, SliceRandom};
use std::{path::Path, process::Command};
use walkdir::{DirEntry, WalkDir};
use xinerama::head_count;

mod config;
mod xinerama;

fn main() -> anyhow::Result<()> {
    let config = Config::new()?;

    let wallpapers = config
        .paths
        .into_iter()
        .flat_map(dir_iter)
        .flatten()
        .filter(|d| {
            !config.exclude.iter().any(|e| d.path().starts_with(e))
                && d.path()
                    .extension()
                    .map(|e| ["png", "jpg"].contains(&&*e.to_string_lossy()))
                    .unwrap_or(false)
        })
        .map(DirEntry::into_path);

    let mut wallpapers = wallpapers.choose_multiple(
        &mut rand::thread_rng(),
        head_count().context("Failed to get head count")? as usize,
    );

    wallpapers.shuffle(&mut rand::thread_rng());

    Command::new("feh")
        .arg("--bg-fill")
        .args(&wallpapers)
        .status()?;

    Ok(())
}

fn dir_iter(p: impl AsRef<Path>) -> impl Iterator<Item = walkdir::Result<DirEntry>> {
    WalkDir::new(p).follow_links(true).into_iter()
}
