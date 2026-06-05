{
  description = "Unified config flake (NixOS + standalone home-manager)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
        inputs.nixgl.overlay
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
      nixosHosts = [ "laptop-nix" ];
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
        };
      };
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs nixosHosts mkNixos;

      homeConfigurations = nixpkgs.lib.genAttrs homeHosts mkHome;

      formatter.${system} = pkgs.nixfmt;

      checks.${system}.pre-commit = pre-commit-check;

      devShells.${system}.default = pkgs.mkShell {
        inherit (pre-commit-check) shellHook;
        buildInputs = pre-commit-check.enabledPackages;
      };

      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust dev shell (rust-overlay, mold, common cargo tools)";
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
