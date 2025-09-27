extraNixpkgsAttrs:
let nixpkgs-src = builtins.fetchGit
    {
      url = "https://github.com/nixos/nixpkgs";
      ref = "master";
      rev ="a683adc19ff5228af548c6539dbc3440509bfed3";
    };
    haskellnix-src = builtins.fetchGit
    {
      url = "https://github.com/input-output-hk/haskell.nix";
      ref = "master";
      rev = "46abef90b4101ff9253a574cf6fbdc74b78a5863";
    };
    haskellnix = import haskellnix-src {};
in import nixpkgs-src
({
  config = haskellnix.nixpkgsArgs.config;
  overlays = haskellnix.nixpkgsArgs.overlays ++ [(import ./overlay.nix)];
} // extraNixpkgsAttrs)
