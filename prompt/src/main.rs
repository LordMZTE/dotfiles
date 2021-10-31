use powerline::{Powerline, modules::{Cmd, Cwd, ExitCode, Git, ReadOnly}};

use crate::theme::Theme;

mod theme;

fn main() {
    let mut main_prompt = Powerline::new();

    main_prompt.add_module(Cwd::<Theme>::new(40, 5, false));
    main_prompt.add_module(Git::<Theme>::new());

    let mut aux_prompt = Powerline::new();

    aux_prompt.add_module(ExitCode::<Theme>::new());
    aux_prompt.add_module(ReadOnly::<Theme>::new());
    aux_prompt.add_module(Cmd::<Theme>::new());

    println!("{}\n{}", main_prompt, aux_prompt);
}
