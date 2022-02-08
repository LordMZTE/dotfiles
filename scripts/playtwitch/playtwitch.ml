Clap.description "play a twitch stream using streamlink";
let stream_name = Clap.mandatory_string ~placeholder:"stream_name" () in
let quality = Clap.default_string ~placeholder:"quality" "best" in
Clap.close ();

let stream_name = "https://twitch.tv/" ^ stream_name in

let exit =
  String.concat " " [ "streamlink"; stream_name; quality ] |> Sys.command
in
if exit != 0 then Stdlib.print_endline "streamlink crashed :("
