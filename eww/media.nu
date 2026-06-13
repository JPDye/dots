# Feeds eww's `media` variable (deflisten in eww.yuck): one compact JSON
# object per metadata change, so yuck can address media.artist, media.title
# and friends. playerctl's own --format can't escape quotes for JSON (a `"`
# in a track title would corrupt it), so the fields travel joined by the
# ASCII unit separator — a byte that never appears in a tag — and are
# rebuilt as JSON here. A player vanishing emits an empty line, which
# becomes all-empty fields; the pills hide themselves on empty strings.
const US = "\u{1f}"

def main [] {
    let fmt = (
        ["{{artist}}", "{{album}}", "{{title}}", "{{duration(mpris:length)}}", "{{status}}"]
        | str join $US
    )

    ^playerctl --follow metadata --format $fmt
    | lines
    | each { |line|
        let p = $line | split row $US
        {
            artist: ($p.0? | default ""),
            album: ($p.1? | default ""),
            title: ($p.2? | default ""),
            duration: ($p.3? | default ""),
            status: ($p.4? | default ""),
        } | to json --raw | print
    }
    | ignore
}

main
