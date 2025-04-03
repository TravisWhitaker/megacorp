extraNixpkgsAttrs:
let nixpkgs-src = builtins.fetchGit
    {
      url = "https://github.com/nixos/nixpkgs";
      ref = "master";
      rev ="b16f158e1b15509ef7ad19032f1b80646f514151";
    };
    haskellnix-src = builtins.fetchGit
    {
      url = "https://github.com/TravisWhitaker/haskell.nix";
      ref = "bootstrap-966";
      rev = "6976ec1bc9a9f3055e16372103a99b1a4cad88d4";
    };
    haskellnix = import haskellnix-src {};
in import nixpkgs-src
({
  config = haskellnix.nixpkgsArgs.config;
  overlays = haskellnix.nixpkgsArgs.overlays ++ [(import ./overlay.nix)];
} // extraNixpkgsAttrs)
