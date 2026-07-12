{
  description = "Unified config flake (NixOS + standalone home-manager)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Pinned older nixpkgs — source of the cached orca-slicer 2.3.2 and
    # bambu-studio builds. nixpkgs 26.11's orca 2.4.1 regressed file dialogs,
    # and its bambu-studio isn't in the binary cache (hour-long local compile).
    # Intentionally NOT `follows nixpkgs`: a separate prebuilt closure is the point.
    nixpkgs-2511.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # `/improve` skill for Claude Code (shadcn/improve): a read-only codebase
    # auditor that writes self-contained execution plans, never editing source.
    # A plain source tree (not a flake) — linked into ~/.claude/skills by
    # modules/dev/claude-code.nix.
    improve-skill = {
      url = "github:shadcn/improve";
      flake = false;
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    textfox = {
      url = "github:adriankarlen/textfox";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    myFonts = {
      url = "path:./fonts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wayland-native launcher (replaces fuzzel). Brings its own backend,
    # elephant, as a transitive input; the home-manager module wires the two.
    walker = {
      url = "github:abenz1267/walker";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Prebuilt nix-index file database (weekly) — powers `, cmd` (comma)
    # without ever running a local `nix-index` crawl.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware-specific NixOS modules. Pure data — no nixpkgs dependency.
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  # Nix guards `nixConfig` with `forceTrivialValue`: every value must be a
  # *literal* (string/bool/int/list-of-strings) written right here — not a
  # `let` binding, not `(import ./caches.nix).substituters`, not any
  # computed expression, or loading the flake errors with "flake configuration
  # setting … is a thunk" (which breaks `nix eval` / `nix flake check`). So the
  # two extra caches are inlined literally below. Keep them in sync with the
  # `extra` list in caches.nix — the source of truth for the system-level
  # substituters in modules/system/nix.nix (those aren't literal-constrained).
  # Drift is caught by `checks.<system>.caches-in-sync` (defined in outputs),
  # which fails `nix flake check` if any caches.nix entry is missing here.
  nixConfig = {
    extra-substituters = [
      "https://helix.cachix.org"
      "https://niri.cachix.org"
    ];
    extra-trusted-public-keys = [
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];
  };

  outputs =
    inputs@{ nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      sharedOverlays = [
        inputs.niri.overlays.niri
        # nixGL's own overlay derives an `isIntelX86Platform` flag from the
        # deprecated `final.system` alias (nixGL flake.nix:36), which prints a
        # "'system' has been renamed to 'stdenv.hostPlatform.system'" warning
        # the moment the desktop forces `pkgs.nixgl.nixGLIntel`. We pin
        # x86_64-linux above, so that flag is unconditionally true here —
        # import nixGL's default.nix directly with the flags inlined to get the
        # byte-identical package set without tripping the deprecation.
        (final: _: {
          nixgl = import "${inputs.nixgl}/default.nix" {
            pkgs = final;
            enable32bits = true;
            enableIntelX86Extensions = true;
          };
        })
        inputs.firefox-addons.overlays.default
      ];

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = sharedOverlays;
      };

      sharedHmModules = [
        inputs.stylix.homeModules.stylix
        inputs.nixcord.homeModules.nixcord
        inputs.niri.homeModules.niri
        ./home.nix
      ];

      mkHome =
        hostname:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = sharedHmModules;
          extraSpecialArgs = { inherit inputs hostname system; };
        };

      mkNixos =
        hostname:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs system hostname; };
          modules = [
            ./hosts/${hostname}/configuration.nix
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = sharedOverlays;
            }
            inputs.home-manager.nixosModules.home-manager
            {
              # `useGlobalPkgs = false` (the default) lets home-manager
              # instantiate its own nixpkgs with its own overlays. Stylix's
              # home module ships an `nixos-icons` overlay it expects to
              # apply itself — sharing system pkgs would warn and drop it.
              # We re-declare allowUnfree + sharedOverlays so HM's pkgs
              # matches the system's.
              home-manager = {
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs hostname system; };
                users.jd.imports = sharedHmModules ++ [
                  {
                    nixpkgs.config.allowUnfree = true;
                    nixpkgs.overlays = sharedOverlays;
                  }
                ];
                backupFileExtension = "hm-backup";
              };
            }
          ];
        };

      # Hosts. NixOS hosts must have `hosts/<name>/configuration.nix` and
      # `hosts/<name>/home.nix` (home-manager runs via the NixOS module).
      # `homeHosts` is for standalone home-manager activation on non-NixOS
      # boxes — never list a NixOS host here or you'll end up with two
      # parallel HM activations fighting over the same files.
      nixosHosts = [
        "jd" "laptop-nix" ];
      homeHosts = [ "desktop-arch" ];

      pre-commit-check = inputs.git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          nixfmt.enable = true;
          deadnix = {
            enable = true;
            # auto-generated; the unused `pkgs` lambda arg is upstream's choice
            excludes = [ "hosts/.*/hardware-configuration\\.nix$" ];
          };
          statix.enable = true;
          # Covers installer/install-host.sh, which is otherwise only checked
          # when the installer ISO actually builds (writeShellApplication).
          shellcheck.enable = true;
          # Reads ./typos.toml (en-gb locale, palette-word allowlist, shader
          # + flake.lock excludes). Also surfaced live in Helix via typos-lsp
          # (toggle per-buffer with Space-q / Space-Q — see modules/dev/helix).
          typos.enable = true;
          # Parse-check the Nushell scripts (eww/*.nu, modules/shell/nushell/*.nu)
          # — they only otherwise fail at runtime (shell startup / eww services).
          nu-check = {
            enable = true;
            name = "nu-check (nushell syntax)";
            files = "\\.nu$";
            language = "system";
            entry = "${
              pkgs.writeShellApplication {
                name = "nu-check-hook";
                runtimeInputs = [ pkgs.nushell ];
                text = ''
                  # pre-commit passes repo-relative paths, but nu-check does not
                  # resolve relative paths against the CWD — absolutise first.
                  rc=0
                  for f in "$@"; do
                    case "$f" in /*) p="$f" ;; *) p="$PWD/$f" ;; esac
                    nu --no-config-file --commands "nu-check --debug \"$p\"" >/dev/null \
                      || { echo "nu-check failed: $f"; rc=1; }
                  done
                  exit $rc
                '';
              }
            }/bin/nu-check-hook";
          };
        };
      };

      # Turns the "KEEP IN SYNC" comment on caches.nix into an enforced invariant.
      # nixConfig values must be literals (see the comment on `nixConfig` above), so
      # the two extra caches are hand-inlined there — AND in the CI workflow's
      # `extra-conf` block (.github/workflows/check.yml, which YAML can't read Nix) —
      # and both copies can silently drift from caches.nix. This check pulls the cache
      # tokens out of BOTH files, restricts them to cachix substituter urls / public
      # keys, and asserts each file's sets equal caches.nix's `extra` exactly — in
      # both directions (a cache present in only one file fails the check). nix flake
      # check runs it (and CI runs nix flake check).
      caches-in-sync =
        let
          inherit (nixpkgs) lib;
          flakeText = builtins.readFile ./flake.nix;
          inherit ((import ./caches.nix)) extra;

          # Every double-quoted token in flake.nix. builtins.split yields match
          # groups as singleton lists; keep those and take the captured string.
          tokens = map builtins.head (
            builtins.filter builtins.isList (builtins.split ''"([^"]*)"'' flakeText)
          );

          isCacheUrl = t: lib.hasPrefix "https://" t && lib.hasSuffix ".cachix.org" t;
          # Also require the "name:key" colon: this check `readFile`s the WHOLE of
          # flake.nix — including this predicate's own ".cachix.org-" literal — and a
          # bare ".cachix.org-" token must not match itself (it would add a spurious
          # entry to declaredKeys and fail the in-sync check). Real keys are
          # "<name>:<base64>", so they carry the colon; the literal does not.
          isCacheKey = t: lib.hasInfix ".cachix.org-" t && lib.hasInfix ":" t;

          sortStr = lib.sort (a: b: a < b);
          declaredUrls = sortStr (lib.unique (builtins.filter isCacheUrl tokens));
          declaredKeys = sortStr (lib.unique (builtins.filter isCacheKey tokens));
          expectedUrls = sortStr (map (c: c.url) extra);
          expectedKeys = sortStr (map (c: c.key) extra);

          # The CI workflow hand-inlines the same caches as unquoted YAML
          # (.github/workflows/check.yml `extra-conf`), so quoted-token
          # extraction can't see them; whitespace-splitting can. The same
          # predicates keep comment words from matching (no bare token in
          # that file is both "https://…*.cachix.org" or "*.cachix.org-*:*"
          # unless it IS a cache literal).
          ciText = builtins.readFile ./.github/workflows/check.yml;
          ciTokens = builtins.filter builtins.isString (builtins.split "[[:space:]]+" ciText);
          ciUrls = sortStr (lib.unique (builtins.filter isCacheUrl ciTokens));
          ciKeys = sortStr (lib.unique (builtins.filter isCacheKey ciTokens));
        in
        assert lib.assertMsg (declaredUrls == expectedUrls && declaredKeys == expectedKeys) ''
          flake.nix nixConfig cache literals are out of sync with caches.nix `extra`.
            declared substituters: ${lib.concatStringsSep ", " declaredUrls}
            expected (caches.nix):  ${lib.concatStringsSep ", " expectedUrls}
            declared keys:          ${lib.concatStringsSep ", " declaredKeys}
            expected keys:          ${lib.concatStringsSep ", " expectedKeys}'';
        assert lib.assertMsg (ciUrls == expectedUrls && ciKeys == expectedKeys) ''
          .github/workflows/check.yml cachix literals are out of sync with caches.nix `extra`.
            declared substituters: ${lib.concatStringsSep ", " ciUrls}
            expected (caches.nix):  ${lib.concatStringsSep ", " expectedUrls}
            declared keys:          ${lib.concatStringsSep ", " ciKeys}
            expected keys:          ${lib.concatStringsSep ", " expectedKeys}'';
        pkgs.runCommand "caches-in-sync" { } "touch $out";

      nixosConfigs = nixpkgs.lib.genAttrs nixosHosts mkNixos;
      homeConfigs = nixpkgs.lib.genAttrs homeHosts mkHome;

      # Bootable installer ISO (installer/iso.nix): a live NixOS carrying this
      # repo plus an `install-host` script that partitions a disk, stamps out
      # hosts/<name>/ and runs nixos-install --flake. Deliberately NOT a
      # nixosHosts member — it has no home-manager, no hosts/ dir, and is only
      # ever built as an image (packages.installer-iso below).
      installer = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          # Prebuilt closure of every NixOS host, baked into the ISO store so
          # installs run near-offline (installer/iso.nix adds the flake input
          # sources on top). Makes the image tens of GB — intentional.
          prebuiltSystems = nixpkgs.lib.mapAttrsToList (
            _: cfg: cfg.config.system.build.toplevel
          ) nixosConfigs;
        };
        modules = [ ./installer/iso.nix ];
      };

      # Home-manager option trees per host, for nixd's option completion
      # (consumed by modules/dev/helix/languages.nix as `.hmOptions.${hostname}`).
      # The path differs by host type: standalone-HM hosts expose `.options`
      # directly, but on NixOS the user's HM options are nested under the system
      # option set and need `getSubOptions` to peel the `home-manager.users.<name>`
      # submodule. Keying by hostname lets nixd look the tree up without knowing
      # which kind of host it's running on.
      hmOptions =
        nixpkgs.lib.genAttrs homeHosts (h: homeConfigs.${h}.options)
        // nixpkgs.lib.genAttrs nixosHosts (
          h: nixosConfigs.${h}.options.home-manager.users.type.getSubOptions [ ]
        );
    in
    {
      nixosConfigurations = nixosConfigs;

      homeConfigurations = homeConfigs;

      inherit hmOptions;

      formatter.${system} = pkgs.nixfmt;

      # `nix build .#installer-iso` → result/iso/nixos-*.iso; flash it to a
      # USB stick to install this flake on a new machine (see README).
      packages.${system}.installer-iso = installer.config.system.build.isoImage;

      # `pre-commit` is the formatting/lint gate; the per-host entries build the
      # real thing (NixOS toplevel / HM activation package) so `nix flake check`
      # catches eval/build breakage before a `switch` does. Derived from the host
      # lists so a new host gets a check for free.
      checks.${system} = {
        pre-commit = pre-commit-check;
        inherit caches-in-sync;
      }
      // nixpkgs.lib.mapAttrs' (
        h: cfg: nixpkgs.lib.nameValuePair "nixos-${h}" cfg.config.system.build.toplevel
      ) nixosConfigs
      // nixpkgs.lib.mapAttrs' (
        h: cfg: nixpkgs.lib.nameValuePair "home-${h}" cfg.activationPackage
      ) homeConfigs;

      devShells.${system}.default = pkgs.mkShell {
        inherit (pre-commit-check) shellHook;
        buildInputs = pre-commit-check.enabledPackages;
      };

      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust dev shell (non-flake shell.nix; rust-overlay, mold, common cargo tools)";
        };
        python = {
          path = ./templates/python;
          description = "Python dev shell (uv, ruff, basedpyright)";
        };
        go = {
          path = ./templates/go;
          description = "Go dev shell (gopls, delve, golangci-lint)";
        };
        typst = {
          path = ./templates/typst;
          description = "Typst dev shell (typst, tinymist, typstyle)";
        };
      };
    };
}
