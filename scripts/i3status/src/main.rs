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
        ColorOrLink,
        Theme,
        ThemeOverrides,
        ThemeUserConfig,
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

    fn override_color(r: u8, g: u8, b: u8) -> Option<ColorOrLink> {
        Some(ColorOrLink::Color(Color::Rgba(Rgba { r, g, b, a: 0xff })))
    }

    let icons = Icons::from_file("material-nf")?;
    let theme = Theme::try_from(ThemeUserConfig {
        theme: Some("slick".into()),
        overrides: Some(ThemeOverrides {
            // dracula theme
            idle_bg: override_color(0x44, 0x47, 0x5a),
            idle_fg: override_color(0xf8, 0xf8, 0xf2),
            info_bg: override_color(0x44, 0x47, 0x5a),
            info_fg: override_color(0xf8, 0xf8, 0xf2),
            good_bg: override_color(0x50, 0xfa, 0x7b),
            good_fg: override_color(0x62, 0x72, 0xa4),
            warning_bg: override_color(0xff, 0xb8, 0x6c),
            warning_fg: override_color(0xbd, 0x93, 0xf9),
            critical_bg: override_color(0xff, 0x55, 0x55),
            critical_fg: override_color(0xbd, 0x93, 0xf9),
            separator: Some(Separator::Custom("\u{e0b2}".to_string())),
            separator_bg: Some(ColorOrLink::Color(Color::Auto)),
            separator_fg: Some(ColorOrLink::Color(Color::Auto)),
            ..Default::default()
        }),
    })?;

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
        format: " $icon {$combo.str(max_w:20, rot_interval:0.1)|} $prev| $play| $next|".parse()?,
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
