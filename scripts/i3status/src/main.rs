#![warn(clippy::pedantic)]
use std::sync::Arc;
use unicode_segmentation::UnicodeSegmentation;

use i3status_rs::{
    blocks,
    config::{BlockConfigEntry, SharedConfig},
    escape::CollectEscaped,
    icons::Icons,
    protocol,
    themes::{
        color::{Color, Rgba},
        separator::Separator,
        Theme,
    },
    widget::{State, Widget},
    BarState,
};

mod catppuccin;

#[tokio::main(flavor = "current_thread")]
async fn main() {
    if let Err(e) = try_main().await {
        let err_widget = Widget::new()
            .with_text(e.to_string().graphemes(true).collect_pango_escaped())
            .with_state(State::Critical);

        serde_json::to_writer(
            std::io::stdout(),
            &err_widget.get_data(&SharedConfig::default(), 0).unwrap(),
        )
        .unwrap();
        println!(",");

        eprintln!("{e}");

        std::future::pending::<()>().await;
    }
}

async fn try_main() -> anyhow::Result<()> {
    env_logger::try_init()?;
    protocol::init(false);

    let icons = Icons(toml::from_str(include_str!("../assets/material-nf.toml"))?);
    let theme = Theme {
        // catppuccin theme
        idle_bg: catppuccin::MANTLE,
        idle_fg: catppuccin::TEXT,
        info_bg: catppuccin::BLUE,
        info_fg: catppuccin::SURFACE[0],
        good_bg: catppuccin::GREEN,
        good_fg: catppuccin::BASE,
        warning_bg: catppuccin::PEACH,
        warning_fg: catppuccin::SURFACE[2],
        critical_bg: catppuccin::RED,
        critical_fg: catppuccin::SURFACE[1],
        separator: Separator::Custom("\u{e0b2}".to_string()),
        separator_bg: Color::Auto,
        separator_fg: Color::Auto,
        alternating_tint_bg: Color::Rgba(Rgba {
            r: 0x11,
            g: 0x11,
            b: 0x11,
            a: 0x00,
        }),
        alternating_tint_fg: Color::Auto,
        end_separator: Separator::Native,
    };

    let mut bar = BarState::new(i3status_rs::config::Config {
        shared: SharedConfig {
            theme: Arc::new(theme),
            icons: Arc::new(icons),
            ..Default::default()
        },
        ..Default::default()
    });

    macro_rules! spawn {
        ($mod:ident $structinit:tt) => {
            bar.spawn_block(BlockConfigEntry {
                config: blocks::BlockConfig::$mod(blocks::$mod::Config $structinit),
                common: Default::default(),
            })
            .await?;
        };
    }

    spawn!(memory {
        format: " $icon $mem_used_percents $mem_used/$mem_avail".parse()?,
        format_alt: Some(" $icon $swap_used_percents $swap_used/$swap_free".parse()?),
        ..Default::default()
    });

    spawn!(cpu {
        interval: 1.into(),
        format: " $icon $frequency $barchart $utilization".parse()?,
        ..Default::default()
    });

    spawn!(temperature {
        interval: 5.into(),
        format: " $icon $min - $average ~ $max +".parse()?,
        chip: Some("*-isa-*".into()),
        idle: Some(40.),
        info: Some(65.),
        warning: Some(80.),
        ..Default::default()
    });

    spawn!(music {
        interface_name_exclude: vec![".*kdeconnect.*".to_string(), "mpd".to_string()],
        format: " $icon {$combo.str(max_w:20, rot_interval:0.1) $prev $play $next|}".parse()?,
        ..Default::default()
    });

    spawn!(sound {
        format: " $icon $output_description{ $volume|}".parse()?,
        ..Default::default()
    });

    spawn!(battery {
        interval: 10.into(),
        format: " $icon $percentage $power".parse()?,
        missing_format: "".parse()?,
        ..Default::default()
    });

    spawn!(time {
        interval: 1.into(),
        format: " $icon $timestamp.datetime(f:'%a %d.%m.%Y %T')".parse()?,
        ..Default::default()
    });

    bar.run_event_loop(|| panic!("Hey! No restarting!")).await?;

    Ok(())
}
