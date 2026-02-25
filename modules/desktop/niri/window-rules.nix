{ config, lib, ... }:

{
  config = lib.mkIf config.dotfiles.desktop.niri.enable {
    programs.niri.settings = {
      window-rules = [
        {
          geometry-corner-radius = {
            top-left = 0.0;
            top-right = 0.0;
            bottom-left = 0.0;
            bottom-right = 0.0;
          };
          clip-to-geometry = true;
          draw-border-with-background = false;
          opacity = 1.0;
        }
        {
          matches = [ { title = "Firefox"; } ];
          opacity = 1.0;
          default-column-width = {
            proportion = 1.0;
          };
        }
        {
          matches = [ { app-id = "Spotify"; } ];
          opacity = 1.0;
          default-column-width = {
            proportion = 1.0;
          };
        }
        {
          matches = [ { app-id = "Slack"; } ];
          opacity = 1.0;
          default-column-width = {
            proportion = 1.0;
          };
        }
        {
          matches = [
            { title = "^(file_progress)$"; }
            { title = "^(confirm)$"; }
            { title = "^(dialog)$"; }
            { title = "^(download)$"; }
            { title = "^(notification )$"; }
            { title = "^(error)$"; }
            { title = "^(splash)$"; }
            { title = "^(nwg-look)$"; }
            { title = "^(confirmreset)$"; }
            { title = "^(Delete profile)$"; }
            { title = "^File Operation Progress$"; }
            { title = "^Confirm to replace files$"; }
            { title = "^KDE Connect URL handler$"; }
            { title = "^(Open File)(.*)$"; }
            { title = "^(Select a File)(.*)$"; }
            { title = "^(Choose wallpaper)(.*)$"; }
            { title = "^(Open Folder)(.*)$"; }
            { title = "^(Save As)(.*)$"; }
            { title = "^(Library)(.*)$"; }
            { title = "^(File Upload)(.*)$"; }
            { title = "^(hyprland-share-picker)$"; }
            { title = "^(.*)-Google$"; }
            { title = "^(.*)System Update$"; }
            { title = "(.*) - Google (.*) - (.*)"; }
            { app-id = "^xdm-app$"; }
            { app-id = "^org.qbittorrent.qBittorrent$"; }
            { app-id = "^org.pulseaudio.pavucontrol$"; }
            { app-id = "^net.davidotek.pupgui2$"; }
          ];
          open-floating = true;
          max-width = 800;
        }
        {
          matches = [ { app-id = ".*blueman.*"; } ];
          open-floating = true;
          min-width = 500;
          max-width = 500;
          min-height = 400;
          max-height = 400;
        }
      ];

      layer-rules = [
        {
          matches = [ { namespace = "^wallpaper$"; } ];
          place-within-backdrop = true;
        }
        {
          matches = [ { namespace = "^eww$"; } ];
          place-within-backdrop = true;
        }
      ];
    };
  };
}
