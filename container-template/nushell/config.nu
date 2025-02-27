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