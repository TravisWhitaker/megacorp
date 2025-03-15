extraNixpkgsAttrs:
let nixpkgs-src = builtins.fetchGit
    {
      url = "https://github.com/nixos/nixpkgs";
      ref = "nixos-24.11";
      rev ="cdd2ef009676ac92b715ff26630164bb88fec4e0";
    };
    haskellnix-src = builtins.fetchGit
    {
      url = "https://github.com/input-output-hk/haskell.nix";
      ref = "master";
      rev = "b5310189cb8a917f4f5f7987f6e5d9ce45ec132d";
    };
    haskellnix = import haskellnix-src {};
in import nixpkgs-src
({
  config = haskellnix.nixpkgsArgs.config;
  overlays = haskellnix.nixpkgsArgs.overlays ++ [(import ./overlay.nix)];
} // extraNixpkgsAttrs)
