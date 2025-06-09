{
  description = "Auth app";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };

  outputs = { nixpkgs, flake-utils, self, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        auth-package = pkgs.buildNpmPackage {
          name = "auth";

          buildInputs = [ pkgs.nodejs ];

          src = self;
          npmDeps = pkgs.importNpmLock { npmRoot = ./.;  };
          npmConfigHook = pkgs.importNpmLock.npmConfigHook;

          installPhase = ''
            mkdir $out
            cp -r ./* $out
          '';
        };

        runner-package = pkgs.writeShellApplication {
          name = "auth";
          runtimeInputs = [ pkgs.nodejs ];
          text = ''
            cd ${auth-package}
            npm run serve
          '';
        };
      in
      {
        apps.default = {
          type = "app";
          program = "${runner-package}/bin/auth";
        };
        packages.default = auth-package;

        devShells.default = pkgs.mkShell { packages = [
          pkgs.bashInteractive
          pkgs.nodejs
          # pkgs.pnpm
        ]; };
      }
    );
}
