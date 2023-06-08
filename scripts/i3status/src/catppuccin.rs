use i3status_rs::themes::color::{Color, Rgba};

const fn c(r: u8, g: u8, b: u8) -> Color {
    Color::Rgba(Rgba { r, g, b, a: 0xff })
}

pub const BASE: Color = c(30, 30, 46);
pub const MANTLE: Color = c(24, 24, 37);
//pub const CRUST: Color = c(17, 17, 27);

pub const SURFACE: [Color; 3] = [c(49, 50, 68), c(69, 71, 90), c(88, 91, 112)];

pub const TEXT: Color = c(205, 214, 244);

pub const RED: Color = c(243, 166, 168);
pub const PEACH: Color = c(250, 179, 172);
pub const GREEN: Color = c(166, 227, 161);
pub const BLUE: Color = c(137, 220, 235);
