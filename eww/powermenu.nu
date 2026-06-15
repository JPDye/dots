# Widget positions as FRACTIONS of the focused output's logical size. niri's
# overview scales the workspace uniformly and centres it, so the dim margin
# around it is the same fraction of the screen on every display — one set of
# fractions therefore lands the widgets in the same spot on a 1080p laptop and
# a 4K monitor alike. (Fixed pixel margins didn't: 80px is a big slice of 1200
# but a sliver of 2160.) Placement is independent of the overview zoom.
#
#   col_x_frac : the right column's horizontal position; the left column
#                mirrors it at (1 - col_x_frac).
#   row_y_frac : the bottom row's vertical position; the top row mirrors it.
#
# So row_y_frac 0.845 -> bottom row at 84.5%, top row at 15.5%. Tune by eye:
# nudge a fraction toward 0.5 to pull that pair toward the centre, toward 1.0
# to push it out toward the screen edges. Edit, then `systemctl --user restart
# eww-powermenu` + toggle the overview — the unit runs this file directly, no
# home-manager switch needed.
# Per-output placement overrides, keyed by niri output name (`niri msg
# outputs`). Each field listed here wins over the orientation default below;
# omit a field to inherit it. Tune these by eye the same way as the defaults.
# eDP-1 is the laptop's internal panel — it keeps the looser 0.845 rows, while
# the landscape default below pulls every other monitor's rows in to 0.835.
const output_overrides = {
    "eDP-1": { row_y_frac: 0.845 },
}

def placement-for [name, logical] {
    let base = if $logical.height > $logical.width {
        # portrait (rotated monitor): its window layout — and so where the gaps
        # fall — differs from landscape, so it keeps its own row value. Untested
        # from here (not the focused output); tune at the desktop if needed.
        { col_x_frac: 0.8, row_y_frac: 0.83 }
    } else {
        # landscape — fractions are resolution-independent, so external monitors
        # share these regardless of size. Columns at the workspace's L/R edges
        # (0.8), rows tucked just inside its top/bottom edges (0.835). The
        # laptop's eDP-1 overrides row_y_frac back out to 0.845 (see above).
        { col_x_frac: 0.8, row_y_frac: 0.835 }
    }

    if $name in $output_overrides {
        $base | merge ($output_overrides | get $name)
    } else {
        $base
    }
}

def compute-geometry [] {
    let focused = (^niri msg --json focused-output | from json | get name)
    let output = (^niri msg --json outputs | from json | get $focused)
    let logical = $output.logical
    let place = (placement-for $focused $logical)

    {
        focused: $focused,
        pad_x: (((1.0 - $place.col_x_frac) * $logical.width) | math round),
        pad_y: (((1.0 - $place.row_y_frac) * $logical.height) | math round),
    }
}

def main [] {
    # A previous instance may have died between open and close, leaving an
    # invisible full-screen window absorbing every click and keypress. The
    # service restarts us, so cleaning up here makes that self-healing.
    try { ^eww close powermenu }

    # The stream is only a wake-up call: rapid toggles queue events faster
    # than one handler runs, and replaying them in order kept opening a menu
    # the user had already left (a quick in/out left the window lingering
    # while stale opens drained). So each event ignores its own payload and
    # reconciles the live overview state against whether the window actually
    # exists — a burst collapses into cheap no-ops and the final state wins.
    niri msg event-stream
    | lines
    | where { |line| $line | str starts-with "Overview toggled: " }
    | each { |_|
        let want = (^niri msg --json overview-state | from json | get is_open)
        let have = (^eww active-windows | lines | any { |w| $w | str starts-with "powermenu" })

        if $want and not $have {
            let cfg = compute-geometry
            # menu-open=false first so the revealer starts hidden and the
            # post-open flip to true plays the fade-in.
            ^eww update $"pad-x=($cfg.pad_x)" $"pad-y=($cfg.pad_y)" "menu-open=false" "confirm="
            ^eww open powermenu --screen $cfg.focused
            ^eww update menu-open=true
        } else if not $want and $have {
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
