{
  colors,
  border-style,
  themeLib,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.dotfiles.desktop.walker;
  # The shadow colour fuzzel used: a quarter-step up the bg0->bg1 ramp, opaque.
  # Drawn as a hard CSS ring (see .box-wrapper) rather than a niri layer-rule
  # shadow, which doesn't render around walker's layer-shell surface.
  shadowColor = themeLib.mix 0.25 colors.bg0 colors.bg1;
in
{
  # Walker's home-manager module pulls in elephant's module too, so importing
  # this one alone gives us `programs.elephant.*`.
  imports = [ inputs.walker.homeManagerModules.default ];

  options.dotfiles.desktop.walker.enable = lib.mkEnableOption "walker launcher" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.walker = {
      enable = true;
      # Run as a user service: Mod+R / Mod+V open instantly, and elephant (the
      # apps/calc/clipboard backend) comes up at session start. Elephant's
      # clipboard provider is what records history — it replaces cliphist, so
      # running both would mean two clipboard managers.
      runAsService = true;
      # Cached nixpkgs build rather than the flake's from-source package.
      package = pkgs.walker;

      # Select our theme. `config` is a freeform TOML attrset whose default is
      # walker's entire bundled config.toml; the module system makes any key we
      # set REPLACE that default wholesale (not merge), so we re-import the
      # bundled config and override only the keys we care about to avoid
      # dropping every other tuneable.
      config =
        let
          base = lib.importTOML "${inputs.walker}/resources/config.toml";
        in
        base
        // {
          theme = "niri";
          # Per-provider input placeholders, key = provider name.
          placeholders = base.placeholders // {
            desktopapplications = {
              input = "search apps";
              list = "No Results";
            };
            clipboard = {
              input = "search clipboard";
              list = "No Results";
            };
          };
        };

      # A theme dir overrides only the files it ships; walker builds the rest
      # from Theme::default() (which embeds every layout — src/theme/mod.rs). So
      # we ship CSS plus a couple of layout tweaks, styled to match niri windows:
      # dark fill, 2px red border, square corners, hard CSS shadow.
      themes.niri.style = ''
        @define-color window_bg_color #${colors.bg0};
        @define-color accent_bg_color #${colors.bg3};
        @define-color theme_fg_color  #${colors.fg1};
        @define-color bright_fg_color #${colors.fg0};
        @define-color dark_fg_color   #${colors.fg2};
        @define-color border_color    #${colors.border};
        @define-color mid_color       #${colors.mid};
        @define-color green_color     #${colors.green};
        @define-color orange_color    #${colors.orange};
        @define-color error_bg_color  #${colors.urgent};
        @define-color error_fg_color  #${colors.fg0};

        * {
          all: unset;
        }

        popover {
          background: lighter(@window_bg_color);
          border: ${toString border-style.width}px solid @border_color;
          border-radius: 0;
          padding: 10px;
        }

        .normal-icons {
          -gtk-icon-size: 16px;
        }

        .large-icons {
          -gtk-icon-size: 32px;
        }

        scrollbar {
          opacity: 0;
        }

        /* The window chrome: matches a niri window — dark fill, 2px red border,
           square corners, and a hard 8px shadow ring (no blur/softening) in the
           fuzzel colour. The shadow is CSS, not a niri layer-rule, because niri
           won't render a shadow that hugs walker's layer-shell surface. */
        .box-wrapper {
          box-shadow: 0 0 0 8px #${shadowColor};
          background: @window_bg_color;
          padding: 20px;
          border-radius: 0;
          border: ${toString border-style.width}px solid @border_color;
        }

        .preview-box,
        .elephant-hint,
        .placeholder {
          color: @theme_fg_color;
        }

        .search-container {
          border-radius: 0;
        }

        /* Pin the variable content row so the launcher stays one size: with
           zero results the list collapses and the window would otherwise
           shrink. 400px matches the scroll's max-content-height. */
        .content-container {
          min-height: 400px;
        }

        .input placeholder {
          opacity: 0.5;
        }

        .input selection {
          background: lighter(lighter(lighter(@window_bg_color)));
        }

        .input {
          caret-color: @theme_fg_color;
          background: lighter(@window_bg_color);
          padding: 10px;
          color: @theme_fg_color;
        }

        .list {
          color: @theme_fg_color;
        }

        .item-box {
          border-radius: 0;
          padding: 10px;
        }

        .item-quick-activation {
          background: alpha(@accent_bg_color, 0.25);
          border-radius: 0;
          padding: 10px;
        }

        child:selected .item-box,
        row:selected .item-box {
          background: alpha(@accent_bg_color, 0.25);
        }

        /* Item subtext — the clipboard entry's timestamp and app descriptions
           in the Mod+R list. Green, and a touch brighter than the default 0.5
           so the colour reads. */
        .item-subtext {
          font-size: 12px;
          color: @green_color;
          opacity: 0.9;
        }

        .providerlist .item-subtext {
          font-size: unset;
          opacity: 0.75;
        }

        /* Clipboard list: copied text in bright white (the preview pane uses a
           darker fg, below). */
        .clipboard .item-text {
          color: @bright_fg_color;
        }

        .item-image-text {
          font-size: 28px;
        }

        .preview {
          border: 1px solid @mid_color;
          border-radius: 0;
          padding: 8px;
          color: @dark_fg_color;
        }

        .calc .item-text {
          font-size: 24px;
        }

        .symbols .item-image {
          font-size: 24px;
        }

        .todo.done .item-text-box {
          opacity: 0.25;
        }

        .todo.urgent {
          font-size: 24px;
        }

        .todo.active {
          font-weight: bold;
        }

        .bluetooth.disconnected {
          opacity: 0.5;
        }

        .preview .large-icons {
          -gtk-icon-size: 64px;
        }

        .keybinds {
          padding-top: 10px;
          border-top: 1px solid lighter(@window_bg_color);
          font-size: 12px;
          color: @theme_fg_color;
        }

        .keybind-button {
          opacity: 0.5;
        }

        .keybind-button:hover {
          opacity: 0.75;
        }

        .keybind-bind {
          text-transform: lowercase;
          opacity: 0.35;
        }

        .keybind-label {
          padding: 2px 4px;
          border-radius: 0;
          border: 1px solid @orange_color;
        }

        .error {
          padding: 10px;
          background: @error_bg_color;
          color: @error_fg_color;
        }

        :not(.calc).current {
          font-style: italic;
        }

        .preview-content.archlinuxpkgs,
        .preview-content.dnfpackages {
          font-family: monospace;
        }
      '';

      # Drop the icon from the app list. The desktopapplications provider uses
      # the generic item.xml; a provider-specific layout overrides it for apps
      # only (files etc. keep their icons). It's item.xml minus the ItemImage /
      # ItemImageFont children — the renderer binds those with `if let Some`
      # (providers/mod.rs), so omitting them just leaves them unset.
      themes.niri.layouts."item_desktopapplications" = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <interface>
          <requires lib="gtk" version="4.0"></requires>
          <object class="GtkBox" id="ItemBox">
            <style>
              <class name="item-box"></class>
            </style>
            <property name="orientation">horizontal</property>
            <property name="spacing">10</property>
            <child>
              <object class="GtkBox" id="ItemTextBox">
                <style>
                  <class name="item-text-box"></class>
                </style>
                <property name="orientation">vertical</property>
                <property name="vexpand">true</property>
                <property name="hexpand">true</property>
                <property name="vexpand-set">true</property>
                <property name="spacing">0</property>
                <child>
                  <object class="GtkLabel" id="ItemText">
                    <style>
                      <class name="item-text"></class>
                    </style>
                    <property name="ellipsize">end</property>
                    <property name="vexpand_set">true</property>
                    <property name="vexpand">true</property>
                    <property name="xalign">0</property>
                  </object>
                </child>
                <child>
                  <object class="GtkLabel" id="ItemSubtext">
                    <style>
                      <class name="item-subtext"></class>
                    </style>
                    <property name="ellipsize">end</property>
                    <property name="vexpand_set">true</property>
                    <property name="vexpand">true</property>
                    <property name="xalign">0</property>
                    <property name="yalign">0</property>
                  </object>
                </child>
              </object>
            </child>
            <child>
              <object class="GtkLabel" id="QuickActivation">
                <style>
                  <class name="item-quick-activation"></class>
                </style>
                <property name="wrap">false</property>
                <property name="valign">center</property>
                <property name="xalign">0</property>
                <property name="yalign">0.5</property>
              </object>
            </child>
          </object>
        </interface>
      '';

    };

    # Pin elephant to the cached nixpkgs build too; it bundles every provider
    # (.so) in lib/elephant/providers, so calc/clipboard/files all work.
    programs.elephant.package = pkgs.elephant;
  };
}
