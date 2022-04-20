use std::process::Command;

#[derive(Copy, Clone)]
pub enum Action {
    Shutdown,
    Reboot,
    Suspend,
    Hibernate,
}

impl Action {
    fn as_command(&self) -> Command {
        let mut cmd = Command::new("systemctl");

        match self {
            Action::Shutdown => cmd.arg("poweroff"),
            Action::Reboot => cmd.arg("reboot"),
            Action::Suspend => cmd.arg("suspend"),
            Action::Hibernate => cmd.arg("hibernate"),
        };

        cmd
    }
}

pub fn run_action(cmd: Action) {
    match cmd.as_command().spawn() {
        Ok(mut c) => {
            let _ = c.wait();
        },
        Err(e) => eprintln!("Error spawning child process: {:?}", e),
    }
}
