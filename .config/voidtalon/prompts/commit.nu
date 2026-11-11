#!/usr/bin/env nu

print $env.VOIDTALON_MODEL
let model = $env.VOIDTALON_MODEL | path parse | get stem

let footer = input --reedline "Footer " --default $"Assisted-by: ($model)"

let tool_note = match (["None", "Forgejo", "Github"] | input list --fuzzy "Upstream Server") {
  "Forgejo" => "You may use the command `fj issue view [NUMBER]` to view an issue given its number."
  "Github" => "You may use the command `gh issue view [NUMBER]` to view an issue given its number."
  _ => ""
}

$"Inspect the currently staged git changes with the `run_command` tool, create a conventional commits
compliant commit message for the changes, then create a fitting commit.  Respect any additional
requirements the user gives for the commit message.

Add this footer: `($footer)`. ($tool_note)" | save $env.VOIDTALON_OUTPUT
