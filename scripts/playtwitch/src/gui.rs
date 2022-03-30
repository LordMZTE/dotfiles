use gtk4::prelude::*;

use crate::start_streamlink;

#[derive(Clone)]
pub struct GuiInitData {
    pub quality: String,
    pub channels: Vec<String>,
}

pub fn run_gui(init: GuiInitData) {
    let app = gtk4::Application::new(Some("de.mzte.playtwitch"), Default::default());
    app.connect_activate(move |app| build_ui(app, &init));
    app.run();
}

fn build_ui(app: &gtk4::Application, init: &GuiInitData) {
    let win = gtk4::ApplicationWindow::builder()
        .application(app)
        .title("Pick a stream!")
        .build();

    let vbox = gtk4::Box::new(gtk4::Orientation::Vertical, 5);
    win.set_child(Some(&vbox));

    let quality_box = gtk4::Box::new(gtk4::Orientation::Horizontal, 5);
    vbox.append(&quality_box);
    quality_box.append(&gtk4::Label::new(Some("Quality")));

    let quality_entry = gtk4::Entry::new();
    quality_box.append(&quality_entry);
    quality_entry.set_hexpand(true);
    quality_entry.set_text(&init.quality);

    let list = gtk4::ListBox::new();
    vbox.append(&list);

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

    let app_ = app.clone();
    list.connect_row_activated(move |_, row| {
        let label = row.child().unwrap().downcast::<gtk4::Label>().unwrap();
        let quality = quality_entry.text().to_string();
        let channel = label.text().to_string();

        std::thread::spawn(move || {
            if let Err(e) = start_streamlink(&channel, &quality) {
                eprintln!("Streamlink Error: {:?}", e);
            }
        });

        app_.quit();
    });

    win.show();
}
