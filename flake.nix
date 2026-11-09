{
  description = "Unified config flake (NixOS + standalone home-manager)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Pinned stable nixpkgs for the slicers. 26.11's orca 2.4.1 regressed file
    # dialogs, and only 26.05 carries bambu-studio's cloud-login fix
    # (nixpkgs#498307: the Bambu network plugin's bundled libcurl needs an
    # explicit CA bundle, and the OAuth webview needs DMA-BUF compositing off).
    # bambu-studio is marked unfree since May 2026 (SFC AGPL ruling,
    # nixpkgs#415821), so Hydra never caches it on ANY branch — expect one
    # local ~1 h compile per lock bump. orca-slicer stays cached.
    # Intentionally NOT `follows nixpkgs`: a separate pinned closure is the point.
    nixpkgs-2605.url = "github:nixos/nixpkgs/nixos-26.05";

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

    # Byteful's Claude Code plugin marketplace (trybyteful/skills). Used here
    # for its `ste100` plugin only: the ASD-STE100 skill, a verbatim copy of
    # danyuchn/asd-ste100-skill with its LICENSE. A plain source tree (not a
    # flake). modules/dev/claude-code.nix links the skill into ~/.claude/skills.
    #
    # The repo is PRIVATE, so any evaluation that has to fetch it needs GitHub
    # credentials with read access. `git+https` rather than `github:` on
    # purpose: Nix's git fetcher runs git, which asks git's credential helper
    # (`gh auth login` provides it locally, README prerequisite 4), whereas
    # `github:` would need an `access-tokens` line in nix.conf. CI writes the
    # BYTEFUL_SKILLS_TOKEN secret into ~/.netrc (see check.yml). The installer
    # ISO bakes the fetched source in, so Path 0 installs stay offline.
    byteful-skills = {
      url = "git+https://github.com/trybyteful/skills";
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

    # The niri binary itself: my fork (local checkout ~/Code/oss/niri), not
    # nixpkgs' release. niri-flake above still supplies the HM module and the
    # settings schema. Push the branch, then `nix flake update niri-fork`.
    niri-fork = {
      url = "github:JPDye/niri/overview-border";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The standalone cargo component for the cargo-sweep timer
    # (modules/dev/cargo-sweep.nix), through `lib.mkRustBin`. nixpkgs' cargo
    # pulls in the whole rustc, about 1.6 GiB, and the timer needs cargo only.
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
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

    # Trial: gj1118/helix, a fork of helix-editor/helix that adds code
    # folding, a file explorer, Lua plugins and more. No binary cache holds
    # the fork, so it builds locally and can follow the root nixpkgs like the
    # other inputs. A revert to upstream needs this URL, the removal of the
    # fork-only block in modules/dev/helix/editor.nix, and the old string
    # form of `bufferline` there. Upstream builds are on helix.cachix.org,
    # but only for helix's own nixpkgs pin, so a revert that wants that cache
    # must also drop the `follows` below.
    helix = {
      url = "github:gj1118/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware-specific NixOS modules. Follows nixpkgs so the lock does
    # not carry a second copy (the modules read pkgs from the importing
    # system either way).
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      sharedOverlays = [
        inputs.niri.overlays.niri
        # Every consumer (HM programs.niri.package, NixOS programs.niri, the
        # greeter, the portal config) reads pkgs.niri, so this one line moves
        # all three hosts onto the fork. No binary cache holds the fork, so it
        # builds locally.
        (final: _: {
          niri = inputs.niri-fork.packages.${final.stdenv.hostPlatform.system}.niri;
        })
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
        "nix-desktop"
        "laptop-nix"
      ];
      homeHosts = [
        "laptop-arch"
      ];

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

      # The installer stamps installer/host-template into hosts/<name>/ and the
      # first evaluation of that host normally happens on the target machine,
      # after the disk is wiped. Evaluating the template here (system half only;
      # the HM overlay needs a hosts/ dir and is covered by the shared modules
      # via the real host checks) makes `nix flake check --no-build` catch
      # template/module drift instead.
      installerTemplate = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs system;
          hostname = "host-template";
        };
        modules = [
          ./installer/host-template/configuration.nix
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = sharedOverlays;
          }
        ];
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

      # nixd (modules/dev/helix/languages.nix) reads hmOptions at editor
      # runtime and nothing else evaluates it, so a home-manager refactor
      # of the users submodule would kill option completion silently.
      # Force one option leaf per host so `nix flake check` fails instead.
      hmOptions-check =
        assert nixpkgs.lib.assertMsg (builtins.all (
          h: (hmOptions.${h}.home.packages.type.name or null) != null
        ) (nixosHosts ++ homeHosts)) "hmOptions no longer resolves for every host";
        pkgs.runCommand "hmOptions-check" { } "touch $out";

      # `nix flake init -t .#<lang>` targets. Two other files must name the
      # same set by hand and cannot import this attrset: the CI pin-bitrot
      # step in .github/workflows/check.yml and the Nushell scaffolders in
      # modules/shell/nushell/scaffolds.nu. `templates-in-sync` below fails
      # `nix flake check` when either drifts, or when a template ships no
      # .envrc (the scaffolder runs `direnv allow` unconditionally).
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
        c = {
          path = ./templates/c;
          description = "C23 dev shell (clang, clangd, sanitizers, valgrind, gdb)";
        };
      };

      # Read the two hand-maintained files,
      # extract the template names they mention, and assert set equality
      # with `templates`. Also assert every template ships an .envrc.
      templates-in-sync =
        let
          inherit (nixpkgs) lib;
          sortStr = lib.sort (a: b: a < b);
          expected = sortStr (builtins.attrNames templates);

          # Every first capture group of `re` in `text`, deduplicated.
          # builtins.split yields match groups as singleton lists; keep those
          # and take the captured string.
          capture =
            re: text: lib.unique (map builtins.head (builtins.filter builtins.isList (builtins.split re text)));

          # The CI step names each template as a `templates/<name>` path (one
          # command per template, no loop, so the literal is visible here).
          ciNames = sortStr (
            capture "templates/([a-z0-9]+)" (builtins.readFile ./.github/workflows/check.yml)
          );

          # Each scaffolder calls `scaffold "<name>"`.
          nuNames = sortStr (
            capture ''scaffold "([a-z0-9]+)"'' (builtins.readFile ./modules/shell/nushell/scaffolds.nu)
          );

          # A template with no .envrc breaks its scaffolder at `direnv allow`.
          # pathExists sees only git-tracked files, so an untracked .envrc
          # fails here too, which is the reminder to `git add` it.
          missingEnvrc = builtins.filter (n: !(builtins.pathExists (templates.${n}.path + "/.envrc"))) (
            builtins.attrNames templates
          );
        in
        assert lib.assertMsg (ciNames == expected) ''
          .github/workflows/check.yml template step is out of sync with flake.nix `templates`.
            named in check.yml:  ${lib.concatStringsSep ", " ciNames}
            expected (flake.nix): ${lib.concatStringsSep ", " expected}'';
        assert lib.assertMsg (nuNames == expected) ''
          modules/shell/nushell/scaffolds.nu is out of sync with flake.nix `templates`.
            scaffolders present:  ${lib.concatStringsSep ", " nuNames}
            expected (flake.nix): ${lib.concatStringsSep ", " expected}'';
        assert lib.assertMsg (missingEnvrc == [ ]) ''
          These templates ship no .envrc, so their init-<name> scaffolder fails at `direnv allow`:
            ${lib.concatStringsSep ", " missingEnvrc}
          Add templates/<name>/.envrc (copy templates/go/.envrc) and `git add` it.'';
        pkgs.runCommand "templates-in-sync" { } "touch $out";

      # The five templates pin nixpkgs by hand in five files: three flake.lock
      # files and two shell.nix fetchTarball calls. Nothing else reads them
      # together, so a partial bump goes unnoticed until `nix flake init`.
      # Assert every pin names one rev and one hash. flake.lock's narHash and
      # fetchTarball's sha256 are the same SRI hash of the unpacked tree, so
      # the two file kinds compare directly.
      #
      # To bump all five to the root flake's nixpkgs, from the repo root:
      #   p=$(jq -c '.nodes[.nodes.root.inputs.nixpkgs].locked' flake.lock)
      #   for t in go python typst; do
      #     jq --argjson p "$p" '.nodes.nixpkgs.locked = $p' templates/$t/flake.lock > /tmp/l && mv /tmp/l templates/$t/flake.lock
      #   done
      #   rev=$(jq -r .rev <<<"$p"); hash=$(jq -r .narHash <<<"$p")
      #   sed -i -E "s|nixos/nixpkgs/archive/[0-9a-f]{40}\.tar\.gz|nixos/nixpkgs/archive/$rev.tar.gz|; 0,/sha256 = \"sha256-[^\"]+\"/s||sha256 = \"$hash\"|" templates/rust/shell.nix templates/c/shell.nix
      # then evaluate each template (the CI step in check.yml lists the commands).
      templates-pin-in-sync =
        let
          inherit (nixpkgs) lib;

          lockPin =
            name:
            let
              locked =
                (builtins.fromJSON (builtins.readFile (templates.${name}.path + "/flake.lock")))
                .nodes.nixpkgs.locked;
            in
            {
              inherit (locked) rev narHash;
            };

          # The nixpkgs fetchTarball block: the url line, then the sha256 line.
          # Anchored on `nixos/nixpkgs/archive/` so rust's second fetchTarball
          # (rust-overlay) does not match. builtins.split yields the two capture
          # groups as one list per match.
          shellPin =
            name:
            let
              text = builtins.readFile (templates.${name}.path + "/shell.nix");
              groups = builtins.filter builtins.isList (
                builtins.split ''nixos/nixpkgs/archive/([0-9a-f]{40})\.tar\.gz";[[:space:]]*sha256 = "([^"]+)";'' text
              );
            in
            assert lib.assertMsg (builtins.length groups == 1)
              "templates/${name}/shell.nix: expected exactly one nixpkgs fetchTarball pin, found ${toString (builtins.length groups)}";
            {
              rev = builtins.elemAt (builtins.head groups) 0;
              narHash = builtins.elemAt (builtins.head groups) 1;
            };

          pinOf =
            name:
            {
              inherit name;
            }
            // (
              if builtins.pathExists (templates.${name}.path + "/flake.lock") then lockPin name else shellPin name
            );
          pins = map pinOf (builtins.attrNames templates);
          revs = lib.unique (map (p: p.rev) pins);
          hashes = lib.unique (map (p: p.narHash) pins);
          describe = lib.concatMapStringsSep "\n    " (p: "${p.name}: ${p.rev} ${p.narHash}") pins;
        in
        assert lib.assertMsg (builtins.length revs == 1 && builtins.length hashes == 1) ''
          Template nixpkgs pins disagree. Bump every template to one rev (procedure in the comment above templates-pin-in-sync in flake.nix).
            ${describe}'';
        pkgs.runCommand "templates-pin-in-sync" { } "touch $out";
    in
    {
      nixosConfigurations = nixosConfigs;

      homeConfigurations = homeConfigs;

      inherit hmOptions;

      formatter.${system} = pkgs.nixfmt;

      packages.${system} = {
        # `nix build .#installer-iso` → result/iso/nixos-*.iso. Flash it to a
        # USB stick to install this flake on a new machine (see README).
        installer-iso = installer.config.system.build.isoImage;

        # `nix run .#arch-pam-setup` → root-level PAM plumbing on the Arch
        # host: the files hyprlock needs to authenticate, plus gnome-keyring
        # PAM integration so apps can store secrets. Standalone home-manager
        # runs as the user and cannot write /etc, so this is a one-time sudo
        # step rather than a module. See hosts/laptop-arch/pam-setup.nix.
        arch-pam-setup = pkgs.callPackage ./hosts/laptop-arch/pam-setup.nix { };
      };

      # `pre-commit` is the formatting/lint gate; the per-host entries build the
      # real thing (NixOS toplevel / HM activation package) so `nix flake check`
      # catches eval/build breakage before a `switch` does. Derived from the host
      # lists so a new host gets a check for free.
      checks.${system} = {
        pre-commit = pre-commit-check;
        inherit
          templates-in-sync
          templates-pin-in-sync
          ;
        installer-template = installerTemplate.config.system.build.toplevel;
        hm-options = hmOptions-check;
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

      inherit templates;
    };
}
