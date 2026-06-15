{
  description = "Go dev shell";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      formatter.${system} = pkgs.nixfmt;

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          go
          gopls
          delve
          golangci-lint
          gotools
        ];
      };
    };
}
