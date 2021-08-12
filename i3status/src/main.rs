use std::{sync::Arc, time::Duration};
use tokio::sync::RwLock;

use crate::json::Block;

mod colors;
mod json;
mod workers;

#[tokio::main]
async fn main() {
    let mut int = tokio::time::interval(Duration::from_millis(100));
    let bar = Arc::new(RwLock::new(Bar::default()));

    spawn_workers(Arc::clone(&bar)).await;

    println!("{}\n[[]", r#"{ "version": 1 }"#);
    loop {
        int.tick().await;
        let bar = bar.read().await;

        let blocks = vec![
            Block {
                full_text: format!("龍 {:>7}", &bar.cpu_freq),
                color: colors::CYAN,
            },
            Block {
                full_text: format!(" {}", &bar.ram),
                color: colors::PURPLE,
            },
            Block {
                full_text: format!("{:>5}", &bar.vol),
                color: colors::ORANGE,
            },
            Block {
                full_text: format!("{:>5}", &bar.battery),
                color: colors::GREEN,
            },
            Block {
                full_text: bar.time.clone(),
                color: colors::WHITE,
            },
        ];

        let json = serde_json::to_string(&blocks).expect("failed to create json");
        println!(",{}", json);
    }
}

async fn spawn_workers(bar: Arc<RwLock<Bar>>) {
    tokio::spawn(workers::ram(Arc::clone(&bar)));
    tokio::spawn(workers::time(Arc::clone(&bar)));
    tokio::spawn(workers::pulseaudio_vol(Arc::clone(&bar)));
    tokio::spawn(workers::cpu_freq(Arc::clone(&bar)));
    tokio::spawn(workers::battery(Arc::clone(&bar)));
}

#[derive(Default)]
struct Bar {
    ram: String,
    time: String,
    vol: String,
    cpu_freq: String,
    battery: String,
}
