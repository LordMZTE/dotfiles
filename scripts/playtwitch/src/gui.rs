use std::{cell::Cell, rc::Rc, thread::JoinHandle};

use gtk4::prelude::*;

use crate::start_streamlink;

#[derive(Clone)]
pub struct GuiInitData {
    pub quality: String,
    pub chatty: bool,
    pub channels: Vec<String>,
}

pub fn run_gui(init: GuiInitData) {
    let streamlink_handle = Rc::new(Cell::new(None));
    let app = gtk4::Application::new(Some("de.mzte.playtwitch"), Default::default());
    let streamlink_handle_ = streamlink_handle.clone();
    app.connect_activate(move |app| build_ui(app, &init, streamlink_handle_.clone()));
    app.run();

    if let Some(handle) = streamlink_handle.take() {
        handle.join().unwrap();
    }
}

fn build_ui(
    app: &gtk4::Application,
    init: &GuiInitData,
    streamlink_handle_out: Rc<Cell<Option<JoinHandle<()>>>>,
) {
    let win = gtk4::ApplicationWindow::builder()
        .application(app)
        .title("Pick a stream!")
        .build();

    let vbox = gtk4::Box::new(gtk4::Orientation::Vertical, 5);
    win.set_child(Some(&vbox));

    let hbox = gtk4::Box::new(gtk4::Orientation::Horizontal, 5);
    vbox.append(&hbox);
    hbox.append(&gtk4::Label::new(Some("Quality")));

    let quality_entry = gtk4::Entry::new();
    hbox.append(&quality_entry);
    quality_entry.set_hexpand(true);
    quality_entry.set_text(&init.quality);

    let chatty_switch = gtk4::Switch::builder()
        .state(init.chatty)
        .tooltip_text("Start Chatty with the given channel")
        .build();
    hbox.append(&chatty_switch);
    hbox.append(&gtk4::Label::new(Some("Start Chatty")));

    let other_channel = gtk4::Entry::builder()
        .placeholder_text("Other Channel...")
        .hexpand(true)
        .build();
    vbox.append(&other_channel);

    // focus other channel initially
    vbox.set_focus_child(Some(&other_channel));

    let win_ = win.clone();
    let quality_entry_ = quality_entry.clone();
    let streamlink_handle_out_ = streamlink_handle_out.clone();
    let chatty_switch_ = chatty_switch.clone();
    other_channel.connect_activate(move |this| {
        let channel = this.text().to_string();
        let quality = quality_entry_.text().to_string();
        let chatty = chatty_switch_.state();

        streamlink_handle_out_.set(Some(std::thread::spawn(move || {
            if let Err(e) = start_streamlink(&channel, &quality, chatty) {
                eprintln!("Streamlink Error: {:?}", e);
            }
        })));

        win_.close();
    });

    let list = gtk4::ListBox::new();
    vbox.append(
        &gtk4::Frame::builder()
            .child(
                &gtk4::ScrolledWindow::builder()
                    .child(&list)
                    .vexpand(true)
                    .vscrollbar_policy(gtk4::PolicyType::Always)
                    .hscrollbar_policy(gtk4::PolicyType::Automatic)
                    .build(),
            )
            .label("Quick Channels")
            .build(),
    );

    for channel in init.channels.iter() {
        let entry = gtk4::ListBoxRow::new();
        entry.set_child(Some(
            &gtk4::Label::builder()
                .label(channel)
                .halign(gtk4::Align::Start)
                .build(),
        ));

        list.append(&entry);
    }

    let win_ = win.clone();
    list.connect_row_activated(move |_, row| {
        let label = row.child().unwrap().downcast::<gtk4::Label>().unwrap();
        let quality = quality_entry.text().to_string();
        let channel = label.text().to_string();
        let chatty = chatty_switch.state();

        streamlink_handle_out.set(Some(std::thread::spawn(move || {
            if let Err(e) = start_streamlink(&channel, &quality, chatty) {
                eprintln!("Streamlink Error: {:?}", e);
            }
        })));

        win_.close();
    });

    win.show();
}
