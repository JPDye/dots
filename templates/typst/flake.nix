{
  description = "Typst dev shell";

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
          typst # compiler (`typst compile main.typ`, `typst watch main.typ`)
          tinymist # LSP — used by helix
          typstyle # formatter (`typstyle format main.typ`)
        ];
      };
    };
}
