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
        self-packages = self.packages.${system};
      in
      {
        devShells.default = pkgs.mkShell { packages = [
          pkgs.bashInteractive
          pkgs.nodejs
          pkgs.pnpm
        ]; };

        apps.default = {
          type = "app";
          program = "${self-packages.run}/bin/run";
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "auth-server";
          version = "0.1.0";
          src = ./.;
          buildInputs = [ pkgs.nodejs pkgs.pnpm.configHook ];

          buildPhase = ''
            pnpm run build
          '';

          installPhase = ''
            mkdir -p $out
            cp package.json $out
            cp -r node_modules $out
            cp -r public $out
            cp -r src $out
          '';

          pnpmDeps = pkgs.pnpm.fetchDeps {
            inherit (self-packages.default) pname version src;
            hash = "sha256-2saQOvsFCQc6EwIpKODGjjlUi8jPzZ15MnR294Lij6g=";
          };
        };

        packages.run = pkgs.writeShellScriptBin "auth-server" ''
          cd ${self-packages.default}
          ${pkgs.pnpm}/bin/pnpm run serve "$@"
        '';
      }
    );
}
