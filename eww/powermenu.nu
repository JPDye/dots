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
    # A previous instance may have died between open and close, leaving an
    # invisible full-screen window absorbing every click and keypress. The
    # service restarts us, so cleaning up here makes that self-healing.
    try { ^eww close powermenu }

    niri msg event-stream
    | lines
    | where { |line| $line | str starts-with "Overview toggled: " }
    | each { |line|
        let state = $line | str replace --all "Overview toggled: " ""

        if $state == "true" {
            let cfg = compute-geometry
            ^eww update $"pad-x=($cfg.pad_x)" $"pad-y=($cfg.pad_y)" "menu-open=false" "confirm="
            ^eww open powermenu --screen $cfg.focused
            ^eww update menu-open=true
        } else if $state == "false" {
            # Close immediately: a fade-out would need the window to outlive
            # the animation (eww can't animate a destroyed window), and niri's
            # overview zoom-out hides the widgets anyway. An instant close also
            # means no window lingers to eat input. If this fails, die loudly
            # and let systemd restart us into the cleanup path above.
            ^eww close powermenu
        }
    }
}

main
