use std::marker::PhantomData;

use powerline::{modules::Module, terminal::Color, Segment};

pub trait FishModeScheme {
    const FISH_MODE_DEFAULT_BG: Color;
    const FISH_MODE_DEFAULT_FG: Color;
    const FISH_MODE_DEFAULT_STR: &'static str = "N";
    const FISH_MODE_INSERT_BG: Color;
    const FISH_MODE_INSERT_FG: Color;
    const FISH_MODE_INSERT_STR: &'static str = "I";
    const FISH_MODE_REPLACE_ONE_BG: Color;
    const FISH_MODE_REPLACE_ONE_FG: Color;
    const FISH_MODE_REPLACE_ONE_STR: &'static str = "R";
    const FISH_MODE_REPLACE_BG: Color;
    const FISH_MODE_REPLACE_FG: Color;
    const FISH_MODE_REPLACE_STR: &'static str = "R";
    const FISH_MODE_VISUAL_BG: Color;
    const FISH_MODE_VISUAL_FG: Color;
    const FISH_MODE_VISUAL_STR: &'static str = "V";
    const FISH_MODE_UNKNOWN_BG: Color;
    const FISH_MODE_UNKNOWN_FG: Color;
    const FISH_MODE_UNKNOWN_STR: &'static str = "?";
}

pub struct FishMode<T> {
    mode: FishModeMode,
    scheme: PhantomData<T>,
}

impl<T: FishModeScheme> FishMode<T> {
    pub fn new() -> Self {
        Self {
            mode: std::env::args()
                .nth(2)
                .map(|s| FishModeMode::from_fish_bind_mode(&s))
                .unwrap_or(FishModeMode::Unknown),
            scheme: PhantomData,
        }
    }
}

impl<T: FishModeScheme> Module for FishMode<T> {
    fn append_segments(&mut self, segments: &mut Vec<Segment>) {
        let (s, bg, fg) = match self.mode {
            FishModeMode::Default => (
                T::FISH_MODE_DEFAULT_STR,
                T::FISH_MODE_DEFAULT_BG,
                T::FISH_MODE_DEFAULT_FG,
            ),
            FishModeMode::Insert => (
                T::FISH_MODE_INSERT_STR,
                T::FISH_MODE_INSERT_BG,
                T::FISH_MODE_INSERT_FG,
            ),
            FishModeMode::Replace => (
                T::FISH_MODE_REPLACE_STR,
                T::FISH_MODE_REPLACE_BG,
                T::FISH_MODE_REPLACE_FG,
            ),
            FishModeMode::ReplaceOne => (
                T::FISH_MODE_REPLACE_ONE_STR,
                T::FISH_MODE_REPLACE_ONE_BG,
                T::FISH_MODE_REPLACE_ONE_FG,
            ),
            FishModeMode::Visual => (
                T::FISH_MODE_VISUAL_STR,
                T::FISH_MODE_VISUAL_BG,
                T::FISH_MODE_VISUAL_FG,
            ),
            FishModeMode::Unknown => (
                T::FISH_MODE_UNKNOWN_STR,
                T::FISH_MODE_UNKNOWN_BG,
                T::FISH_MODE_UNKNOWN_FG,
            ),
        };

        segments.push(Segment::simple(s, fg, bg));
    }
}

enum FishModeMode {
    Default,
    Insert,
    ReplaceOne,
    Replace,
    Visual,
    Unknown,
}

impl FishModeMode {
    fn from_fish_bind_mode(mode: &str) -> Self {
        match mode {
            "default" => Self::Default,
            "insert" => Self::Insert,
            "replace_one" => Self::ReplaceOne,
            "replace" => Self::Replace,
            "visual" => Self::Visual,
            _ => Self::Unknown,
        }
    }
}
