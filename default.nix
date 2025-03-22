extraNixpkgsAttrs:
let nixpkgs-src = builtins.fetchGit
    {
      url = "https://github.com/nixos/nixpkgs";
      ref = "master";
      rev ="649ec09a79814cef3a214d2d17339364fb651892";
    };
    haskellnix-src = builtins.fetchGit
    {
      url = "https://github.com/TravisWhitaker/haskell.nix";
      ref = "bootstrap-966";
      rev = "796badfa303b002359a2cc36b528cbb47c23128b";
    };
    haskellnix = import haskellnix-src {};
in import nixpkgs-src
({
  config = haskellnix.nixpkgsArgs.config;
  overlays = haskellnix.nixpkgsArgs.overlays ++ [(import ./overlay.nix)];
} // extraNixpkgsAttrs)
