use powerline::{
    modules::{CmdScheme, CwdScheme, ExitCodeScheme, GitScheme, ReadOnlyScheme},
    terminal::Color,
};

use crate::fish_mode::FishModeScheme;

// convenience alias
const fn c(color: u8) -> Color {
    Color(color)
}

pub struct Theme;

impl CmdScheme for Theme {
    const CMD_PASSED_FG: Color = c(4);
    const CMD_PASSED_BG: Color = c(2);
    const CMD_FAILED_BG: Color = c(1);
    const CMD_FAILED_FG: Color = c(7);
}

impl CwdScheme for Theme {
    const CWD_FG: Color = c(0);
    const PATH_FG: Color = c(0);
    const PATH_BG: Color = c(3);
    const HOME_FG: Color = c(0);
    const HOME_BG: Color = c(5);
    const SEPARATOR_FG: Color = c(4);
}

impl GitScheme for Theme {
    const GIT_AHEAD_BG: Color = c(2);
    const GIT_AHEAD_FG: Color = c(0);
    const GIT_BEHIND_BG: Color = c(4);
    const GIT_BEHIND_FG: Color = c(0);
    const GIT_STAGED_BG: Color = c(6);
    const GIT_STAGED_FG: Color = c(0);
    const GIT_NOTSTAGED_BG: Color = c(4);
    const GIT_NOTSTAGED_FG: Color = c(0);
    const GIT_UNTRACKED_BG: Color = c(69);
    const GIT_UNTRACKED_FG: Color = c(0);
    const GIT_CONFLICTED_BG: Color = c(1);
    const GIT_CONFLICTED_FG: Color = c(0);
    const GIT_REPO_CLEAN_BG: Color = c(4);
    const GIT_REPO_CLEAN_FG: Color = c(0);
    const GIT_REPO_DIRTY_BG: Color = c(250);
    const GIT_REPO_DIRTY_FG: Color = c(0);
    const GIT_REPO_ERROR_BG: Color = c(196);
    const GIT_REPO_ERROR_FG: Color = c(0);
}

impl ExitCodeScheme for Theme {
    const EXIT_CODE_BG: Color = c(5);
    const EXIT_CODE_FG: Color = c(0);
}

impl ReadOnlyScheme for Theme {
    const READONLY_FG: Color = c(1);
    const READONLY_BG: Color = c(0);
}

impl FishModeScheme for Theme {
    const FISH_MODE_DEFAULT_BG: Color = c(3);
    const FISH_MODE_DEFAULT_FG: Color = c(0);
    const FISH_MODE_INSERT_BG: Color = c(2);
    const FISH_MODE_INSERT_FG: Color = c(0);
    const FISH_MODE_REPLACE_ONE_BG: Color = c(5);
    const FISH_MODE_REPLACE_ONE_FG: Color = c(0);
    const FISH_MODE_REPLACE_BG: Color = c(4);
    const FISH_MODE_REPLACE_FG: Color = c(0);
    const FISH_MODE_VISUAL_BG: Color = c(5);
    const FISH_MODE_VISUAL_FG: Color = c(0);
    const FISH_MODE_UNKNOWN_BG: Color = c(1);
    const FISH_MODE_UNKNOWN_FG: Color = c(0);
}
