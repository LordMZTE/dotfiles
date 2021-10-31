use powerline::{Powerline, modules::{Cmd, Cwd, ExitCode, Git, ReadOnly}};

use crate::theme::Theme;

mod theme;

fn main() {
    let mut prompt = Powerline::new();

    prompt.add_module(ReadOnly::<Theme>::new());
    prompt.add_module(Cwd::<Theme>::new(40, 5, false));
    prompt.add_module(Git::<Theme>::new());
    prompt.add_module(ExitCode::<Theme>::new());
    prompt.add_module(Cmd::<Theme>::new());

    println!("{}", prompt);
}
