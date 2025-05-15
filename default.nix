extraNixpkgsAttrs:
let nixpkgs-src = builtins.fetchGit
    {
      url = "https://github.com/nixos/nixpkgs";
      ref = "master";
      rev ="b16f158e1b15509ef7ad19032f1b80646f514151";
    };
    haskellnix-src = builtins.fetchGit
    {
      url = "https://github.com/input-output-hk/haskell.nix";
      ref = "master";
      rev = "d39a9850ab7c9ebe0f3ec6a50548cfc310978aae";
    };
    haskellnix = import haskellnix-src {};
in import nixpkgs-src
({
  config = haskellnix.nixpkgsArgs.config;
  overlays = haskellnix.nixpkgsArgs.overlays ++ [(import ./overlay.nix)];
} // extraNixpkgsAttrs)
