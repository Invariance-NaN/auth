{
  description = "A simple MFA app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nodeDependencies = (pkgs.callPackage ./node-composition.nix { pkgs = pkgs; }).nodeDependencies;
      in
      {
        devShells.default = pkgs.mkShell { packages = [
          pkgs.bashInteractive
          pkgs.nodejs
          pkgs.node2nix
        ]; };

        packages.default = pkgs.stdenv.mkDerivation {
          name = "auth";
          src = ./.;
          buildInputs = [ pkgs.nodejs ];
          buildPhase = ''
            ln -s ${nodeDependencies}/lib/node_modules ./node_modules
            export PATH="${nodeDependencies}/bin:$PATH"

            npm run build
            cp -r node_modules $out/
            cp -r public $out/
            cp -r src $out/
            cp -r package.json $out/
          '';
        };
      }
    );
}
