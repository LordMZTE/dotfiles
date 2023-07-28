//! Utilities to determine the GPU the system is running.

pub enum Type {
    NVidia,
    Amd,
    Unknown,
}

impl Type {
    pub fn get() -> anyhow::Result<Self> {
        if std::fs::try_exists("/sys/module/nvidia")? {
            return Ok(Type::NVidia);
        }

        // TODO: is it called amdgpu?
        if std::fs::try_exists("/sys/module/amdgpu")? {
            return Ok(Type::Amd);
        }

        Ok(Type::Unknown)
    }
}
