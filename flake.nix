{
  description = "impeccable-flutter: design skill and deterministic detector for Flutter";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {pkgs = nixpkgs.legacyPackages.${system};});
  in {
    devShells = forEachSupportedSystem ({pkgs}: {
      # The detector is plain Dart with no Flutter dependency, so this shell
      # stays small; the fixture app it runs against lives in ../flutter-tests.
      default = pkgs.mkShell {
        packages = with pkgs; [
          dart
          gnumake
          perl
        ];

        shellHook = ''
          # dart writes to ~/.dart-tool and the pub cache; keep both in-tree so
          # a clean checkout behaves the same as a warm one.
          export PUB_CACHE="$PWD/.pub-cache"
          export PATH="$PWD/detector/.dart_tool/bin:$PATH"

          echo "impeccable-flutter · $(dart --version 2>&1)"
          echo "  make test      # detector unit + fixture tests"
          echo "  make detect P=<path>   # run the detector over a Flutter project"
        '';
      };
    });
  };
}
