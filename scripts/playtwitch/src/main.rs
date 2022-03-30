use std::{
    fs::File,
    io::{BufRead, BufReader},
    process::Command,
};

use anyhow::Context;
use clap::Parser;
use gui::GuiInitData;

mod gui;

#[derive(Parser)]
struct Opt {
    /// Name of the channel to play. If omitted, a GUI selector is opened.
    channel: Option<String>,

    /// Quality of the stream. See streamlink docs.
    #[clap(default_value = "best")]
    quality: String,
}

fn main() -> anyhow::Result<()> {
    let opt = Opt::parse();

    if let Some(channel) = opt.channel {
        start_streamlink(&channel, &opt.quality)?;
    } else {
        let channels_path = dirs::config_dir()
            .context("Couldn't get config path")?
            .join("playtwitch/channels");

        let channels = BufReader::new(File::open(channels_path)?)
            .lines()
            .collect::<Result<Vec<_>, _>>()?;

        gui::run_gui(GuiInitData {
            quality: opt.quality,
            channels,
        });
    }

    Ok(())
}

fn start_streamlink(channel: &str, quality: &str) -> anyhow::Result<()> {
    println!(
        "Starting streamlink with channel {} and quality {}",
        channel, quality
    );

    Command::new("streamlink")
        .arg(format!("https://twitch.tv/{}", channel))
        .arg(quality)
        .spawn()?
        .wait()?;

    Ok(())
}
