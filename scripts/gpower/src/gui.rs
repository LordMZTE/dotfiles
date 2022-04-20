use std::{
    cell::Cell,
    rc::Rc,
    thread::{self, JoinHandle},
};

use gtk4::{prelude::*, Inhibit};

use crate::handler::{self, Action};

pub fn on_activate(handle_out: Rc<Cell<Option<JoinHandle<()>>>>, app: &gtk4::Application) {
    let win = gtk4::ApplicationWindow::new(app);
    win.set_modal(true);
    win.set_resizable(false);
    win.set_icon_name(Some("system-shutdown"));
    let content = gtk4::Box::new(gtk4::Orientation::Horizontal, 20);
    content.set_margin_start(20);
    content.set_margin_end(20);
    content.set_margin_top(20);
    content.set_margin_bottom(20);
    win.set_child(Some(&content));

    let key_event_controller = gtk4::EventControllerKey::new();
    content.add_controller(&key_event_controller);
    let win_ = win.clone();
    key_event_controller.connect_key_pressed(move |_, key, _, _| {
        if key == gtk4::gdk::Key::Escape {
            win_.close();
            Inhibit(true)
        } else {
            Inhibit(false)
        }
    });

    content.append(&power_button(
        handle_out.clone(),
        win.clone(),
        Action::Shutdown,
        "system-shutdown",
        "Shutdown",
    ));
    content.append(&power_button(
        handle_out.clone(),
        win.clone(),
        Action::Reboot,
        "system-reboot",
        "Reboot",
    ));
    content.append(&power_button(
        handle_out.clone(),
        win.clone(),
        Action::Suspend,
        "system-suspend",
        "Suspend",
    ));
    content.append(&power_button(
        handle_out,
        win.clone(),
        Action::Hibernate,
        "system-hibernate",
        "Hibernate",
    ));

    win.show();
}

fn power_button(
    handle_out: Rc<Cell<Option<JoinHandle<()>>>>,
    win: gtk4::ApplicationWindow,
    action: Action,
    icon: &str,
    text: &str,
) -> gtk4::Box {
    let vbox = gtk4::Box::new(gtk4::Orientation::Vertical, 2);
    let btn = gtk4::Button::new();
    vbox.append(&btn);
    btn.set_child(Some(
        &gtk4::Image::builder()
            .icon_name(icon)
            .pixel_size(60)
            .build(),
    ));
    btn.connect_clicked(move |_| {
        handle_out.set(Some(thread::spawn(move || handler::run_action(action))));
        win.close();
    });
    vbox.append(&gtk4::Label::new(Some(text)));

    vbox
}
