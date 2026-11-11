#!/usr/bin/env nu

let target_lang = input --reedline "Target language " --default "English"

$"Translate the following text into ($target_lang).
Respond with only the translated text.  If you have any additional notes, add them after the translated text, separated by a horizontal rule \(`---`\)." | save $env.VOIDTALON_OUTPUT
