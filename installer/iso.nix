# Bootable installer ISO that carries this repo and a guided `install-host`
# script (partition [+ optional LUKS] → hardware-configuration.nix → stamp
# hosts/<name>/ from ./host-template → register in nixosHosts →
# nixos-install --flake).
#
#   nix build .#installer-iso        # → result/iso/nixos-*.iso
#
# The ISO is deliberately fat: it bakes in every host's prebuilt closure
# (`prebuiltSystems`, from flake.nix) plus the source of every locked flake
# input, so an install is near-offline — only the delta from the new machine's
# hardware-configuration.nix gets built. After that, keeping the machine
# current is an ordinary online rebuild.
#
# Not a "host" in the hosts/ sense: no home-manager, never in nixosHosts, and
# never `switch`ed to — it's built once per flash via the packages output.
{
  lib,
  pkgs,
  inputs,
  prebuiltSystems,
  modulesPath,
  ...
}:

let
  caches = import ../caches.nix;

  # Shown above the prompt on every console at boot (getty helpLine → the
  # /etc/issue banner) and re-printable any time via `install-help`.
  installSteps = ''
    ------------------------------------------------------------------
     jd dotfiles installer

     1. get online. run `nmtui`. not required.
     2. install. run `install-host`. answer prompts, walk away.
     3. reboot.
     4. push. run `cd ~/.config/nix; git push origin install-<host>`.
        merge into main.

     show these steps again: install-help
    ------------------------------------------------------------------
  '';

  install-help = pkgs.writeShellScriptBin "install-help" ''
    cat <<'EOF'
    ${installSteps}
    EOF
  '';

  # Every locked flake input, transitively (genericClosure is cycle-safe;
  # non-flake inputs have no `inputs` attr). With these in the ISO store,
  # `nixos-install --flake` evaluates offline: fetchTree resolves each input
  # to its narHash-derived store path instead of hitting the network.
  inputSources = map (i: i.flake.outPath) (
    builtins.genericClosure {
      startSet = [
        {
          key = inputs.self.outPath;
          flake = inputs.self;
        }
      ];
      operator =
        item:
        map (f: {
          key = f.outPath;
          flake = f;
        }) (builtins.attrValues (item.flake.inputs or { }));
    }
  );

  install-host = pkgs.writeShellApplication {
    name = "install-host";
    # nixos-generate-config / nixos-install / nixos-enter / udevadm come from
    # the ISO's system PATH (writeShellApplication only prepends to it).
    runtimeInputs = with pkgs; [
      coreutils
      cryptsetup
      dosfstools
      e2fsprogs
      git
      parted
      util-linux
    ];
    runtimeEnv = {
      FLAKE_SRC = "${inputs.self}";
      REPO_URL = "https://github.com/JPDye/dots.git";
      SELF_REV = inputs.self.rev or "";
      TEMPLATE_DIR = "${./host-template}";
      STATE_VERSION = lib.trivial.release;
    };
    text = builtins.readFile ./install-host.sh;
  };
in
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  isoImage = {
    # The near-offline payload (merged with the base module's live-system
    # closure). This is what makes the image tens of GB instead of ~1.
    storeContents = prebuiltSystems ++ inputSources;

    # The default (zstd level 19) takes hours over a store this size; level 3
    # builds in minutes for a modestly larger image.
    squashfsCompression = "zstd -Xcompression-level 3";

    appendToMenuLabel = " (jd dotfiles installer)";
  };

  # nmtui beats the minimal CD's raw wpa_supplicant for install-time wifi.
  networking.wireless.enable = lib.mkForce false;
  networking.networkmanager.enable = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Same extra caches the installed system trusts (modules/system/nix.nix),
    # so whatever delta the baked-in closure doesn't cover substitutes instead
    # of compiling.
    inherit (caches) substituters;
    trusted-public-keys = caches.trustedPublicKeys;
    # Don't let unreachable substituters stall a fully offline install: give
    # up on them quickly and build locally.
    connect-timeout = 5;
    fallback = true;
  };

  environment.systemPackages = [
    install-host
    install-help
  ];

  services.getty.helpLine = "\n" + installSteps;

  system.stateVersion = lib.trivial.release;
}
