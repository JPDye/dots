def main [] {
    let monitors = {
        "DP-7":  { pad_x: "20.5", pad_y: "10", spacing_y: "755" }
        "eDP-1": { pad_x: "20.5", pad_y: "10", spacing_y: "755" }
    }
    let default = { pad_x: "20.5", pad_y: "10", spacing_y: "755" }

    niri msg event-stream
    | lines
    | where { |line| $line | str starts-with "Overview toggled: " }
    | each { |line|
        let state = $line | str replace --all "Overview toggled: " ""

        if $state == "true" {
            let focused = (niri msg --json focused-output | from json | get name)
            let cfg = ($monitors | get -i $focused | default $default)
            run-external eww update $"pad-x=($cfg.pad_x)" $"pad-y=($cfg.pad_y)" $"spacing-y=($cfg.spacing_y)"
            sleep 0.1sec
            run-external eww open powermenu --screen $focused
        } else if $state == "false" {
            try {
                run-external eww close powermenu
            }
        }
    }
}

main
