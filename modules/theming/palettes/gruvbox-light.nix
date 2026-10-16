# Gruvbox light, hard contrast, from github.com/morhetz/gruvbox.
#
# The only light scheme in this flake. It publishes `polarity = "light"`,
# which palette.nix passes on to stylix, the base16 `variant`, the greeter's
# Adwaita and Claude Code's TUI theme.
#
# The token names are the same as in the dark schemes, so every consumer
# works unchanged: `bg*` is the paper ramp and `fg*` is the ink ramp. bg0 is
# `light0_hard`. The accents are upstream's "faded" set, the cut gruvbox
# itself uses for text on a light background. The ANSI table uses the
# "neutral" set, as upstream's own terminal ports do.
{ plib }:

let
  inherit (plib) mix;

  # Upstream's neutral accents, for the ANSI normal slots only.
  neutralHues = {
    red = "cc241d";
    green = "98971a";
    yellow = "d79921";
    blue = "458588";
    purple = "b16286";
    aqua = "689d6a";
  };

  colors = rec {
    bg0 = "f9f5d7"; # light0_hard
    bg1 = "ebdbb2"; # light1
    bg2 = "d5c4a1"; # light2
    bg3 = "bdae93"; # light3

    # A bar fill one half-step under bg0, so a bar separates from the editor.
    bgSunken = mix 0.5 bg0 "fbf1c7"; # toward light0

    # The muted at-rest tint: a neutral step tinted toward the accent, as in
    # the kintsugi scheme.
    mid = mix 0.25 bg2 red;

    fg3 = "665c54"; # dark3
    fg2 = "504945"; # dark2
    fg1 = "3c3836"; # dark1
    fg0 = "282828"; # dark0

    white = "7c6f64"; # dark4
    grey = "928374"; # gray

    # Upstream's faded accents.
    red = "9d0006";
    green = "79740e";
    yellow = "b57614";
    orange = "af3a03";
    blue = "076678";
    pink = "8f3f71"; # purple
    aqua = "427b58";

    # The kintsugi hue names, mapped onto their nearest gruvbox equivalents,
    # as in the dark gruvbox scheme. eww/eww.scss reads `goldDeep`.
    gold = yellow;
    paleGold = neutralHues.yellow;
    amber = orange;
    coral = red;
    salmon = pink;
    goldDeep = mix 0.25 yellow bg0;
    goldDeepHover = mix 0.40 yellow bg0;

    # The warm surface ramp: bg0 mixed toward orange. On paper the steps grow
    # darker, which keeps the same order of prominence as on a dark scheme.
    warm1 = mix 0.03 bg0 orange;
    warm2 = mix 0.08 bg0 orange;
    warm3 = mix 0.10 bg0 orange;
    warm4 = mix 0.14 bg0 orange;
    warm5 = mix 0.20 bg0 orange;
    warm6 = mix 0.30 bg0 orange;
    warm7 = mix 0.45 bg0 orange;
    warm8 = mix 0.58 bg0 orange;

    # The hard seam colour. On paper a seam must be darker than the surface
    # it sits under, so it goes toward bg2, not bg1.
    shadow = mix 0.5 bg0 bg2;
    shadowInactive = mix 0.35 bg0 bg2;

    borderMid = warm6;
    borderMidHover = warm7;

    gradient1 = red;
    gradient2 = pink;
    gradient3 = orange;
    gradient4 = yellow;
    gradient5 = green;
    gradient6 = blue;

    # ---- Semantic roles ----------------------------------------------
    primary = orange;
    secondary = red;
    tertiary = yellow;

    accent = orange;

    borderInactive = bg3;
    borderActive = orange;
    border = borderActive;
    neutral = bg3;
    urgent = red;
    failure = red;
    success = green;
    warning = yellow;
    info = blue;

    # Hover steps. On paper a hover lifts toward the ink, not toward white,
    # so the blend target is black.
    borderActiveHover = mix 0.25 borderActive "000000";
    accentHover = mix 0.25 accent "000000";
    primaryHover = mix 0.25 primary "000000";
    secondaryHover = mix 0.25 secondary "000000";
    tertiaryHover = mix 0.25 tertiary "000000";
    successHover = mix 0.25 success "000000";
    warningHover = mix 0.25 warning "000000";
    urgentHover = mix 0.25 urgent "000000";
    infoHover = mix 0.25 info "000000";
  };

  # Upstream gruvbox's own syntax colours, as gruvbox.vim paints them.
  syntax = {
    comment = colors.grey;
    commentTodo = colors.fg0;
    escape = colors.orange;
    function = colors.green;
    number = colors.pink;
    string = colors.green;
    type = colors.yellow;
    commentModifiers = [ "italic" ];
    keywordModifiers = [ ];
    typeModifiers = [ ];
    storage = colors.orange;
    generic = colors.yellow;
    macro = colors.aqua;
    method = colors.green;
    variable = colors.blue;
    constructor = colors.pink;
    operator = colors.fg1;
    punctuation = colors.fg2;
    annotation = colors.aqua;
  };

  # Upstream's terminal mapping: neutral accents for the normal slots,
  # faded accents for the bright slots. Black and white swap places on a
  # light terminal, so slot 0 is the paper and slot 15 is the ink.
  ansi = [
    colors.bg0 # 0  black
    neutralHues.red # 1  red
    neutralHues.green # 2  green
    neutralHues.yellow # 3  yellow
    neutralHues.blue # 4  blue
    neutralHues.purple # 5  magenta
    neutralHues.aqua # 6  cyan
    colors.fg3 # 7  white
    colors.grey # 8  bright black
    colors.red # 9  bright red
    colors.green # 10 bright green
    colors.yellow # 11 bright yellow
    colors.blue # 12 bright blue
    colors.pink # 13 bright magenta
    colors.aqua # 14 bright cyan
    colors.fg1 # 15 bright white
  ];

  # Upstream gruvbox's syntax mapping on the base16 slots, which stylix
  # paints into the targets it owns.
  base16 = {
    base08 = colors.blue; # variables
    base09 = colors.pink; # constants, numbers
    base0A = colors.yellow; # types
    base0B = colors.green; # strings
    base0C = colors.aqua; # escapes
    base0D = colors.green; # functions
    base0E = colors.red; # keywords
    base0F = colors.orange;
  };
in
{
  polarity = "light";
  inherit
    colors
    syntax
    ansi
    base16
    ;
}
