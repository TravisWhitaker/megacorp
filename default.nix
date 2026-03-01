extraNixpkgsAttrs:
let nixpkgs-src = builtins.fetchGit
    {
      url = "https://github.com/nixos/nixpkgs";
      ref = "nixos-25.11";
      rev ="1267bb4920d0fc06ea916734c11b0bf004bbe17e";
    };
    haskellnix-src = builtins.fetchGit
    {
      url = "https://github.com/input-output-hk/haskell.nix";
      ref = "master";
      rev = "0f4ef613dd6c1c19fe4b391f2ec8dcb487a1dff7";
    };
    haskellnix = import haskellnix-src {};
in import nixpkgs-src
({
  config = haskellnix.nixpkgsArgs.config;
  overlays = haskellnix.nixpkgsArgs.overlays ++ [(import ./overlay.nix)];
} // extraNixpkgsAttrs)
