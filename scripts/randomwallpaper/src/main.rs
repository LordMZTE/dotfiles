use anyhow::Context;
use rand::prelude::{IteratorRandom, SliceRandom};
use std::{
    path::{Path, PathBuf},
    process::Command,
};
use walkdir::{DirEntry, WalkDir};
use xinerama::head_count;

mod xinerama;

fn main() -> anyhow::Result<()> {
    let paths = [
        PathBuf::from("/usr/share/backgrounds"),
        Path::new(&std::env::var("HOME").context("couldn't get home directory")?)
            .join(".local/share/backgrounds"),
    ];

    let wallpapers = paths
        .into_iter()
        .flat_map(dir_iter)
        .flatten()
        .filter(|d| {
            d.path()
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
