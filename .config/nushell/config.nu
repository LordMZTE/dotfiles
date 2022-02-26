# Nushell Config File

# Use nushell functions to define your right and left prompt
let-env PROMPT_COMMAND = { 
    zoxide add -- $nu.cwd

    ^prompt $env.LAST_EXIT_CODE insert
}

let-env PROMPT_COMMAND_RIGHT = { "" }

# The prompt indicators are environmental variables that represent
# the state of the prompt
let-env PROMPT_INDICATOR = ""
let-env PROMPT_INDICATOR_VI_INSERT = ""
let-env PROMPT_INDICATOR_VI_NORMAL = ""
let-env PROMPT_MULTILINE_INDICATOR = ""

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running extrnal commands (to_string)
let-env ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) }
    to_string: { |v| $v | str collect (char esep) }
  }
  "Path": {
    from_string: { |s| $s | split row (char esep) }
    to_string: { |v| $v | str collect (char esep) }
  }
}
def-env z [...rest:string] {
    cd (zoxide query --exclude ($nu.cwd) -- $rest.0 | str collect | str trim)
}

alias nv = nvim
alias la = ls -la
alias nvide = neovide --multigrid --

# for more information on themes see
# https://github.com/nushell/nushell/blob/main/docs/How_To_Coloring_and_Theming.md
let default_theme = {
    # color for nushell primitives
    separator: white
    leading_trailing_space_bg: { attr: b }
    header: green_bold
    empty: blue
    bool: white
    int: white
    filesize: white
    duration: white
    date: white
    range: white
    float: white
    string: white
    nothing: white
    binary: white
    cellpath: white
    row_index: green_bold
    record: white
    list: white
    block: white
    hints: dark_gray

    # shapes are used to change the cli syntax highlighting
    shape_garbage: { fg: "#FFFFFF" bg: "#FF0000" attr: b}
    shape_bool: light_cyan
    shape_int: purple_bold
    shape_float: purple_bold
    shape_range: yellow_bold
    shape_internalcall: cyna_bold
    shape_external: cyan
    shape_externalarg: green_bold
    shape_literal: blue
    shape_operator: yellow
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_datetime: cyan_bold
    shape_list: cyan_bold
    shape_table: blue_bold
    shape_record: cyan_bold
    shape_block: blue_bold
    shape_filepath: cyan
    shape_globpattern: cyan_bold
    shape_variable: purple
    shape_flag: blue_bold
    shape_custom: green
    shape_nothing: light_cyan
}

# The default config record. This is where much of your global configuration is setup.
let $config = {
  filesize_metric: $false
  table_mode: compact_double # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
  use_ls_colors: $true
  rm_always_trash: $false
  color_config: $default_theme
  use_grid_icons: $true
  footer_mode: "25" # always, never, number_of_rows, auto
  quick_completions: $true  # set this to $false to prevent auto-selecting completions when only one remains
  animate_prompt: $false # redraw the prompt every second
  float_precision: 2
  use_ansi_coloring: $true
  filesize_format: "auto" # b, kb, kib, mb, mib, gb, gib, tb, tib, pb, pib, eb, eib, zb, zib, auto
  edit_mode: vi # emacs, vi
  max_history_size: 10000
  menu_config: {
    columns: 4
    col_width: 20   # Optional value. If missing all the screen width is used to calculate column width
    col_padding: 2
    text_style: green
    selected_text_style: green_reverse
    marker: "| "
  }
  history_config: {
    page_size: 10
    selector: ":"
    text_style: green
    selected_text_style: green_reverse
    marker: "? "
  }
  keybindings: [
    {
      name: completion
      modifier: control
      keycode: char_t
      mode: vi_insert # emacs vi_normal vi_insert
      event: { send: menu name: context_menu }
    }
  ]
}
