{
  description = "Auth app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    bun2nix = {
      url = "github:baileyluTCD/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, flake-utils, bun2nix, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bashInteractive
            pkgs.nodejs
            pkgs.bun
            bun2nix.packages.${system}.default

            pkgs.node-gyp
            pkgs.nodePackages.node-gyp-build

            pkgs.stdenv.cc.cc.lib
          ];
        };
      }
    );
}
