use serde::Serialize;
#[derive(Debug, Serialize)]
pub struct Block {
    pub full_text: String,
    // this is always a const color string, so this is fine for now
    pub color: &'static str,
}
