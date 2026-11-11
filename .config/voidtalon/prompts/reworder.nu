#!/usr/bin/env nu

let style = input --reedline "Target style " --default "professional"

$"Reword the following text to a ($style)-sounding style.  Output only the reworded text." | save $env.VOIDTALON_OUTPUT
