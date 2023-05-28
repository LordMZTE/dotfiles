use std::sync::Arc;

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

#[tokio::main(flavor = "current_thread")]
async fn main() {
    if let Err(e) = try_main().await {
        let err_widget = Widget::new()
            .with_text(e.to_string().chars().collect_pango_escaped())
            .with_state(State::Critical);

        serde_json::to_writer(
            std::io::stdout(),
            &err_widget.get_data(&Default::default(), 0).unwrap(),
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

    fn color(r: u8, g: u8, b: u8) -> Color {
        Color::Rgba(Rgba { r, g, b, a: 0xff })
    }

    let icons = Icons(toml::from_str(include_str!("../assets/material-nf.toml"))?);
    let theme = Theme {
        // dracula theme
        idle_bg: color(0x44, 0x47, 0x5a),
        idle_fg: color(0xf8, 0xf8, 0xf2),
        info_bg: color(0x44, 0x47, 0x5a),
        info_fg: color(0xf8, 0xf8, 0xf2),
        good_bg: color(0x50, 0xfa, 0x7b),
        good_fg: color(0x62, 0x72, 0xa4),
        warning_bg: color(0xff, 0xb8, 0x6c),
        warning_fg: color(0xbd, 0x93, 0xf9),
        critical_bg: color(0xff, 0x55, 0x55),
        critical_fg: color(0xbd, 0x93, 0xf9),
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
