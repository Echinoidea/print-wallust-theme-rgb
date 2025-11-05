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

        # Define your OCaml dependencies
        ocamlDeps = with ocamlPackages; [
          # Your specified libraries
          sexplib
          ppx_sexp_conv # PPX for sexplib
          # Note: 'unix' and 'str' are part of OCaml stdlib, no separate package needed
          # Note: 'camlfetch' is your local library in /lib, handled by Dune

          # Build tools
          dune_3
          ocaml
          findlib

          # Development tools
          ocaml-lsp
          ocamlformat
          utop # Interactive REPL
        ];

      in {
        devShells.default = pkgs.mkShell {
          buildInputs = ocamlDeps ++ [
            # System dependencies
            pkgs.pkg-config
            pkgs.glibc
            pkgs.glibc.static

            # System info tools (for camlfetch)
            pkgs.glxinfo # GPU/OpenGL info
            pkgs.xorg.xdpyinfo # X11 display info
            pkgs.pciutils # lspci
            pkgs.usbutils # lsusb
            pkgs.coreutils # Basic utilities
          ];

          shellHook = ''
            echo "🐫 OCaml development environment"
            echo "  OCaml version: $(ocaml --version)"
            echo "  Dune version: $(dune --version)"
            echo ""
            echo "Available commands:"
            echo "  dune build       - Build your project"
            echo "  dune exec        - Execute your program"
            echo "  dune test        - Run tests"
            echo "  utop             - Interactive REPL"
            echo "  ocamlformat      - Format OCaml code"
          '';
        };

        # Optional: Define a package build
        packages.default = ocamlPackages.buildDunePackage {
          pname = "camlfetch";
          version = "0.1.0";
          src = ./.;

          buildInputs = ocamlDeps;

          # Dune will handle the build
          # If you have a specific dune profile, you can specify it:
          # buildPhase = "dune build --profile=release";
        };
      });
}
