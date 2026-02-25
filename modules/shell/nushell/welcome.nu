def welcome [] {
  # Wait briefly for the PTY to report its real size at startup
  mut width = (term size).columns
  if $width == 0 {
    sleep 100ms
    $width = (term size).columns
  }

  if $width > 0 and $width < 80 {
    let visible_width = 50
    let pad = [((($width - $visible_width) / 2) | math floor) 0] | math max
    ^fastfetch --logo nixos_small --logo-padding-top 6 --logo-padding-left $pad
  } else {
    let visible_width = 75
    let pad = if $width > 0 {
      [((($width - $visible_width) / 2) | math floor) 0] | math max
    } else {
      0
    }
    ^fastfetch --logo nixos --logo-padding-top 0 --logo-padding-left $pad
  }
}
