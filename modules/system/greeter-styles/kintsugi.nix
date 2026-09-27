# ReGreet stylesheet for the kintsugi scheme.
#
# The login box copies the hyprlock card and a focused niri window: a bg0
# fill, the warm `borderActive` outline, square corners, and the hard seam
# shadow in `shadow`, moved `shadow-style.offset` down and right. Inside it,
# the fields sit on the warm surface ramp, the Login button is solid gold,
# and every at-rest outline is a rung of the same warm ramp.
#
# ReGreet's UI is a GtkOverlay (see `src/gui/templates.rs` upstream): the
# background Picture is child 1, the login Frame is child 2, and the clock
# Frame is child 3. The notification bar and the Reboot / Power Off buttons
# sit in a Box after them. Every rule below overrides the stock Adwaita look,
# so no blue accent is left.
{
  colors,
  border-style,
  shadow-style,
  themeLib,
}:

let
  c = colors;
  bw = "${toString border-style.width}px";
  radius = "${toString border-style.radius-int}px";
  shadowRgba = "rgba(${themeLib.rgbCss c.shadow}, ${toString shadow-style.opacity})";
  offset = "${toString shadow-style.offset}px";
in
''
  /* Login box and clock: niri-window frames. */
  overlay > frame.background:nth-child(2),
  overlay > frame.background:nth-child(3) {
    background-color: #${c.bg0};
    color: #${c.fg0};
    border-radius: ${radius};
  }

  overlay > frame.background:nth-child(2) {
    border: ${bw} solid #${c.borderActive};
    box-shadow: ${offset} ${offset} 0 0 ${shadowRgba};
  }

  /* The clock hangs from the top edge, so it keeps no top border. */
  overlay > frame.background:nth-child(3) {
    border: ${bw} solid #${c.borderInactive};
    border-top-width: 0;
    box-shadow: ${offset} ${offset} 0 0 ${shadowRgba};
    color: #${c.primary};
  }

  /* Field labels ("User:", "Session:") recede. The bold status line on the
     top row takes the gold accent. */
  overlay > frame.background:nth-child(2) grid > label {
    color: #${c.fg2};
  }

  overlay > frame.background:nth-child(2) grid > label:first-child {
    color: #${c.accent};
  }

  /* Text fields, the password field included. */
  entry {
    background-color: #${c.warm2};
    background-image: none;
    color: #${c.fg0};
    caret-color: #${c.primary};
    border: ${bw} solid #${c.borderMid};
    border-radius: ${radius};
    box-shadow: none;
    outline: none;
  }

  entry:focus-within {
    border-color: #${c.borderActive};
    background-color: #${c.warm3};
  }

  entry > text > placeholder {
    color: #${c.fg3};
  }

  entry > text > selection,
  label > selection {
    background-color: #${c.warm7};
    color: #${c.fg0};
  }

  entry image {
    color: #${c.fg2};
  }

  entry image:hover {
    color: #${c.primary};
  }

  /* Plain buttons: Cancel, the dropdowns, the edit toggles. */
  button {
    background-color: #${c.warm2};
    background-image: none;
    color: #${c.fg0};
    border: ${bw} solid #${c.borderMid};
    border-radius: ${radius};
    box-shadow: none;
    outline: none;
    text-shadow: none;
  }

  button:hover {
    background-color: #${c.warm4};
    border-color: #${c.borderMidHover};
  }

  button:active,
  button:checked {
    background-color: #${c.warm5};
    border-color: #${c.accent};
    color: #${c.primary};
  }

  button:focus-visible {
    border-color: #${c.borderActive};
  }

  /* Login: solid gold with dark text, the one filled button on the page. */
  button.suggested-action {
    background-color: #${c.primary};
    border-color: #${c.primary};
    color: #${c.shadow};
  }

  button.suggested-action:hover {
    background-color: #${c.primaryHover};
    border-color: #${c.primaryHover};
  }

  button.suggested-action:active {
    background-color: #${c.accent};
    border-color: #${c.accent};
  }

  button.suggested-action:focus-visible {
    border-color: #${c.fg0};
  }

  /* Reboot and Power Off: an outline in the theme's red, filled on hover. */
  button.destructive-action {
    background-color: #${c.bg0};
    border-color: #${c.urgent};
    color: #${c.urgent};
    box-shadow: ${offset} ${offset} 0 0 ${shadowRgba};
  }

  button.destructive-action:hover {
    background-color: #${c.urgent};
    color: #${c.shadow};
  }

  button.destructive-action:active {
    background-color: #${c.urgentHover};
    border-color: #${c.urgentHover};
    color: #${c.shadow};
  }

  /* Dropdown menus of the user and session pickers. */
  popover > contents {
    background-color: #${c.bg0};
    color: #${c.fg0};
    border: ${bw} solid #${c.borderActive};
    border-radius: ${radius};
    box-shadow: none;
  }

  popover > arrow {
    background-color: #${c.bg0};
    border: ${bw} solid #${c.borderActive};
  }

  popover *:hover,
  popover *:selected {
    background-color: #${c.warm5};
    color: #${c.primary};
  }

  /* Notification bar above the power buttons. */
  infobar > revealer > box {
    background-color: #${c.bg0};
    color: #${c.fg0};
    border: ${bw} solid #${c.borderMid};
    border-radius: ${radius};
  }

  infobar.error > revealer > box {
    border-color: #${c.failure};
    color: #${c.failure};
  }

  infobar.warning > revealer > box {
    border-color: #${c.warning};
    color: #${c.warning};
  }

  tooltip,
  tooltip > * {
    background-color: #${c.bg0};
    color: #${c.fg0};
    border-radius: ${radius};
  }

  tooltip {
    border: ${bw} solid #${c.borderMid};
  }
''
