# Distance in logical px from the overview edge to the bar (in the dim margin)
const MARGIN_X = 0
const MARGIN_Y = 80

def compute-geometry [] {
    let zoom = ($env.NIRI_OVERVIEW_ZOOM? | default "0.6" | into float)
    let focused = (^niri msg --json focused-output | from json | get name)
    let output = (^niri msg --json outputs | from json | get $focused)
    let logical = $output.logical
    let w = $logical.width
    let h = $logical.height

    let inset_x = ((1.0 - $zoom) / 2.0 * $w)
    let inset_y = ((1.0 - $zoom) / 2.0 * $h)
    let pad_x = (($inset_x - $MARGIN_X) | math round)
    let pad_y = (($inset_y - $MARGIN_Y) | math round)

    {
        focused: $focused,
        pad_x: $pad_x,
        pad_y: $pad_y,
    }
}

def main [] {
    niri msg event-stream
    | lines
    | where { |line| $line | str starts-with "Overview toggled: " }
    | each { |line|
        let state = $line | str replace --all "Overview toggled: " ""

        if $state == "true" {
            let cfg = compute-geometry
            ^eww update $"pad-x=($cfg.pad_x)" $"pad-y=($cfg.pad_y)"
            sleep 0.1sec
            ^eww open powermenu --screen $cfg.focused
        } else if $state == "false" {
            try {
                ^eww close powermenu
            }
        }
    }
}

main
