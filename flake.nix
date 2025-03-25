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
        run-script-name = "auth-server-run";
        pnpm = pkgs.pnpm_10;
      in
      {
        devShells.default = pkgs.mkShell { packages = [
          pkgs.bashInteractive
          pkgs.nodejs
          pnpm
        ]; };

        apps.default = {
          type = "app";
          program = "${self-packages.run}/bin/${run-script-name}";
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "auth-server";
          version = "0.1.0";
          src = ./.;
          builder = ./builder.sh;
          buildInputs = [ pkgs.nodejs pnpm.configHook ];

          buildPhase = ''
            pnpm run build
          '';

          installPhase = ''
            mkdir -p $out
            cp package.json $out
            cp -r node_modules $out
            cp -r src $out
          '';

          pnpmDeps = pnpm.fetchDeps {
            inherit (self-packages.default) pname version src;
            hash = "sha256-2saQOvsFCQc6EwIpKODGjjlUi8jPzZ15MnR294Lij6g=";
          };
        };

        packages.run = pkgs.writeShellScriptBin run-script-name ''
          cd ${self-packages.default}
          ${pnpm}/bin/pnpm run serve "$@"
        '';

        pnpmInstallFlags = [ "--ignore-scripts=false" ];
      }
    );
}
