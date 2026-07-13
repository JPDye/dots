# Form-factor profile for desktops — counterpart to profiles/laptop.nix.
# Currently thin: its whole job is to make the "no battery" assumptions
# explicit (and to be the obvious home for future desktop-only config).
_:

{
  # No battery ⇒ no TLP/upower. This matches power.nix's default (false), but
  # is stated explicitly so the profile documents intent and stays correct if
  # that default ever changes.
  dotfiles.system.power.enable = false;
}
