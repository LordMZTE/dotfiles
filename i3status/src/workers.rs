use crate::Bar;
use chrono::Local;
use heim::units::frequency::megahertz;
use heim::{memory::os::linux::MemoryExt, units::information::megabyte};

use std::sync::Arc;
use std::time::Duration;
use tokio::process::Command;
use tokio::sync::RwLock;

pub(crate) async fn ram(bar: Arc<RwLock<Bar>>) {
    let mut int = tokio::time::interval(Duration::from_secs(1));

    loop {
        let mem = heim::memory::memory().await;
        let ram;
        if let Ok(mem) = mem {
            ram = format!(
                "{}MB/{}MB",
                mem.used().get::<megabyte>(),
                mem.free().get::<megabyte>()
            );
        } else {
            ram = String::from("error reading ram :(");
        }
        bar.write().await.ram = ram;
        int.tick().await;
    }
}

pub(crate) async fn time(bar: Arc<RwLock<Bar>>) {
    let mut int = tokio::time::interval(Duration::from_millis(200));

    loop {
        let time = Local::now().format("%a %d.%m.%Y %T").to_string();

        bar.write().await.time = time;
        int.tick().await;
    }
}

pub(crate) async fn pulseaudio_vol(bar: Arc<RwLock<Bar>>) {
    let mut int = tokio::time::interval(Duration::from_secs(2));

    loop {
        let res = Command::new("pactl")
            .arg("get-sink-volume")
            .arg("@DEFAULT_SINK@")
            .output()
            .await
            .ok()
            .and_then(|o| String::from_utf8(o.stdout).ok());

        let mute = Command::new("pactl")
            .arg("get-sink-mute")
            .arg("@DEFAULT_SINK@")
            .output()
            .await
            .map(|o| o.stdout.contains(&b'y'))
            .unwrap_or(false);

        let msg;

        match res {
            Some(out) => {
                // get first line
                let out = out.lines().next().unwrap_or(&out);
                let volumes = out
                    .split(' ')
                    .filter(|s| s.contains('%'))
                    .map(|s| s.trim().replace('%', "").parse::<u8>())
                    .collect::<Result<Vec<_>, _>>()
                    .unwrap_or_else(|_| vec![]);

                let mut avg = 0u8;
                for v in &volumes {
                    avg += v / volumes.len() as u8;
                }

                let symbol = if mute { '遼' } else { '蓼' };

                msg = format!("{} {}%", symbol, avg);
            }
            None => msg = String::from("PA Error :("),
        }

        bar.write().await.vol = msg;
        int.tick().await;
    }
}

pub(crate) async fn cpu_freq(bar: Arc<RwLock<Bar>>) {
    let mut int = tokio::time::interval(Duration::from_secs(2));

    loop {
        let freq = heim::cpu::frequency().await;
        let txt;
        if let Ok(freq) = freq {
            let freq = freq.current().get::<megahertz>();
            txt = format!("{}MHz", freq);
        } else {
            txt = String::from("Error reading CPU frequency :(");
        }
        bar.write().await.cpu_freq = txt;
        int.tick().await;
    }
}

pub(crate) async fn battery(bar: Arc<RwLock<Bar>>) {
    enum BatteryState {
        Charging,
        Discharging,
        NotCharging,
    }

    let mut int = tokio::time::interval(Duration::from_secs(10));

    loop {
        let out = Command::new("acpi")
            .output()
            .await
            .ok()
            .and_then(|o| String::from_utf8(o.stdout).ok());

        let txt;
        if let Some(s) = out {
            if let Some(bat) = s.lines().next() {
                let percent = bat.split(&[' ', ','][..]).find(|s| s.contains('%')).unwrap_or("0%");
                let state = if bat.contains("Charging") {
                    BatteryState::Charging
                } else if bat.contains("Discharging") {
                    BatteryState::Discharging
                } else {
                    BatteryState::NotCharging
                };

                let icon = match state {
                    BatteryState::Charging => '',
                    BatteryState::Discharging => '',
                    BatteryState::NotCharging => '',
                };

                txt = format!("{} {}", icon, percent);
            } else {
                txt = String::from("No bat")
            }
        } else {
            txt = String::from("Battery Error :(");
        }

        bar.write().await.battery = txt;
        int.tick().await;
    }
}
