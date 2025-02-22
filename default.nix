extraNixpkgsAttrs:
let nixpkgs-src = builtins.fetchGit
    {
      url = "https://github.com/nixos/nixpkgs";
      ref = "master";
      rev ="3ac3a47fd4705dde1e2138cb184800dff7b3505b";
    };
    haskellnix-src = builtins.fetchGit
    {
      url = "https://github.com/input-output-hk/haskell.nix";
      ref = "master";
      rev = "81eb79ff6065dfd00b7e5ce46d636fc32a1efef4";
    };
    haskellnix = import haskellnix-src {};
in import nixpkgs-src
({
  config = haskellnix.nixpkgsArgs.config;
  overlays = haskellnix.nixpkgsArgs.overlays ++ [(import ./overlay.nix)];
} // extraNixpkgsAttrs)
