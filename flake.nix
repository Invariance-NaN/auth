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
        pnpm = pkgs.pnpm_10;
      in
      {
        devShells.default = pkgs.mkShell { packages = [
          pkgs.bashInteractive
          pkgs.nodejs
          pnpm
        ]; };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "my-app";
          version = "0.1.0";
          src = ./.;
          buildInputs = [ pkgs.nodejs pnpm.configHook ];

          buildPhase = ''
            pnpm rb
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
            hash = "sha256-vYsjdAZ4ceJ6sHZwNboL/wvS47RvMLx8bmWWB5v3/SM=";
          };
        };
      }
    );
}
