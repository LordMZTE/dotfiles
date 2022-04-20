use std::{cell::Cell, rc::Rc};

use gtk4::prelude::*;

mod gui;
mod handler;

fn main() {
    let app = gtk4::Application::new(
        Some("de.mzte.gpower"),
        gtk4::gio::ApplicationFlags::FLAGS_NONE,
    );

    let handle = Rc::new(Cell::new(None));

    let handle_ = handle.clone();
    app.connect_activate(move |app| gui::on_activate(handle_.clone(), app));
    app.run();

    if let Some(handle) = handle.take() {
        let _ = handle.join();
    }
}
