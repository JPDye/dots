# ReGreet stylesheet for the gruvbox scheme.
#
# The login box reads like a focused niri window under gruvbox: a bg0 fill,
# the red `borderActive` outline, the shared 1px corner radius, and a hard bg0 ring with
# no blur, `shadow-style.offset` plus 4px wide. Inside it, the fields sit on
# the bg1 / bg2 neutrals, and the Login button is solid orange.
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
  ring = "0 0 0 ${
    toString (shadow-style.offset + 4)
  }px rgba(${themeLib.rgbCss c.bg0}, ${toString shadow-style.opacity})";
in
''
  /* Login box and clock. */
  overlay > frame.background:nth-child(2),
  overlay > frame.background:nth-child(3) {
    background-color: #${c.bg0};
    color: #${c.fg1};
    border-radius: ${radius};
  }

  overlay > frame.background:nth-child(2) {
    border: ${bw} solid #${c.borderActive};
    box-shadow: ${ring};
  }

  /* The clock hangs from the top edge, so it keeps no top border. */
  overlay > frame.background:nth-child(3) {
    border: ${bw} solid #${c.borderInactive};
    border-top-width: 0;
    color: #${c.fg0};
  }

  /* Field labels ("User:", "Session:") recede. The bold status line on the
     top row takes the orange accent. */
  overlay > frame.background:nth-child(2) grid > label {
    color: #${c.fg3};
  }

  overlay > frame.background:nth-child(2) grid > label:first-child {
    color: #${c.accent};
  }

  /* Text fields, the password field included. */
  entry {
    background-color: #${c.bg1};
    background-image: none;
    color: #${c.fg1};
    caret-color: #${c.accent};
    border: ${bw} solid #${c.bg2};
    border-radius: ${radius};
    box-shadow: none;
    outline: none;
  }

  entry:focus-within {
    border-color: #${c.borderActive};
  }

  entry > text > placeholder {
    color: #${c.fg3};
  }

  entry > text > selection,
  label > selection {
    background-color: #${c.bg3};
    color: #${c.fg0};
  }

  entry image {
    color: #${c.fg3};
  }

  entry image:hover {
    color: #${c.accent};
  }

  /* Plain buttons: Cancel, the dropdowns, the edit toggles. */
  button {
    background-color: #${c.bg1};
    background-image: none;
    color: #${c.fg1};
    border: ${bw} solid #${c.bg2};
    border-radius: ${radius};
    box-shadow: none;
    outline: none;
    text-shadow: none;
  }

  button:hover {
    background-color: #${c.bg2};
    border-color: #${c.bg3};
  }

  button:active,
  button:checked {
    background-color: #${c.bg2};
    border-color: #${c.accent};
    color: #${c.fg0};
  }

  button:focus-visible {
    border-color: #${c.borderActive};
  }

  /* Login: solid orange with dark text. */
  button.suggested-action {
    background-color: #${c.primary};
    border-color: #${c.primary};
    color: #${c.bg0};
  }

  button.suggested-action:hover {
    background-color: #${c.primaryHover};
    border-color: #${c.primaryHover};
  }

  button.suggested-action:focus-visible {
    border-color: #${c.fg0};
  }

  /* Reboot and Power Off: a red outline, filled on hover. */
  button.destructive-action {
    background-color: #${c.bg0};
    border-color: #${c.urgent};
    color: #${c.urgent};
  }

  button.destructive-action:hover {
    background-color: #${c.urgent};
    color: #${c.bg0};
  }

  button.destructive-action:active {
    background-color: #${c.urgentHover};
    border-color: #${c.urgentHover};
    color: #${c.bg0};
  }

  /* Dropdown menus of the user and session pickers. */
  popover > contents {
    background-color: #${c.bg0};
    color: #${c.fg1};
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
    background-color: #${c.bg2};
    color: #${c.fg0};
  }

  /* Notification bar above the power buttons. */
  infobar > revealer > box {
    background-color: #${c.bg0};
    color: #${c.fg1};
    border: ${bw} solid #${c.bg2};
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
    color: #${c.fg1};
    border-radius: ${radius};
  }

  tooltip {
    border: ${bw} solid #${c.bg2};
  }
''
