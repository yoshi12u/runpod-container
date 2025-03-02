$env.config = {
    edit_mode: vi
    show_banner: false
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: fuzzy
    }
    keybindings: [
        {
            name: forward_char
            modifier: control
            keycode: char_f
            mode: [vi_insert]
            event: { 
                until: [
                    { send: HistoryHintComplete}
                    { send: MenuRight}
                    { edit: MoveRight }
                ]
            }
        }
        {
            name: backward_char
            modifier: control
            keycode: char_b
            mode: [vi_insert]
            event: { 
                until: [
                    { send: MenuLeft}
                    { edit: MoveLeft }
                ]
            }
        }
        {
            name: backspace
            modifier: control
            keycode: char_h
            mode: [emacs, vi_insert]
            event: { edit: Backspace }
        }
        {
            name: exit
            modifier: control
            keycode: char_d
            mode: [emacs, vi_normal, vi_insert]
            event: { 
                send: executehostcommand 
                cmd: "exit" 
            }
        }
    ]
}

$env.STARSHIP_SHELL = "nu"

def create_left_prompt [] {
    starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

$env.PROMPT_COMMAND = { || create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = ""

$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ": "
$env.PROMPT_INDICATOR_VI_NORMAL = "〉"
$env.PROMPT_MULTILINE_INDICATOR = "::: "
