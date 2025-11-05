{
  description = "OCaml development environment with Dune";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ocamlPackages = pkgs.ocaml-ng.ocamlPackages_5_3;
        ocamlDeps = with ocamlPackages; [
          sexplib
          ppx_sexp_conv
          dune_3
          ocaml
          findlib
          ocaml-lsp  
          ocamlformat
          utop
        ];
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = ocamlDeps ++ [
            pkgs.pkg-config
            pkgs.glibc
            pkgs.glibc.static
          ];
          shellHook = ''
            echo "🐫 OCaml development environment"
            echo "  OCaml version: $(ocaml --version)"
            echo "  Dune version: $(dune --version)"
            echo "  LSP available: $(which ocaml-lsp || echo 'not found')"
            echo ""
            echo "Available commands:"
            echo "  dune build       - Build your project"
            echo "  dune exec        - Execute your program"
            echo "  dune test        - Run tests"
            echo "  utop             - Interactive REPL"
            echo "  ocamlformat      - Format OCaml code"
          '';
        };
        packages.default = ocamlPackages.buildDunePackage {
          pname = "wallust-theme-previews";
          version = "0.1.0";
          src = ./.;
          buildInputs = ocamlDeps;
        };
      });
}
