use std::mem::MaybeUninit;

use anyhow::bail;
use x11::{
    xinerama::{XineramaIsActive, XineramaQueryScreens},
    xlib::{XCloseDisplay, XFree, XOpenDisplay},
};

pub fn head_count() -> anyhow::Result<i32> {
    unsafe {
        let display = XOpenDisplay(b":0\0".as_ptr() as _);
        if display.is_null() {
            bail!("Couldn't open display");
        }

        if XineramaIsActive(display) != 1 {
            XCloseDisplay(display);
            bail!("Xinerama is inactive");
        }

        let mut screens = MaybeUninit::uninit();

        let info = XineramaQueryScreens(display, screens.as_mut_ptr());
        if info.is_null() {
            XCloseDisplay(display);
            bail!("Failed to query screens");
        }

        let count = screens.assume_init();

        XFree(info as _);
        XCloseDisplay(display);

        Ok(count)
    }
}
