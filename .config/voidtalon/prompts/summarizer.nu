#!/usr/bin/env nu

let verbosity = ["concise", "detailed"] | input list --fuzzy "Verbosity?"

$"Summarize the following text.  Output nothing except a ($verbosity) summary." | save $env.VOIDTALON_OUTPUT
