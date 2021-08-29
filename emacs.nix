{ }:
let

  pkgs = import <nixpkgs> { overlays = [ (import ./overlay.nix) ]; };

  myEmacs = pkgs.emacsWithPackagesFromUsePackage {
    config = builtins.readFile ./init.el;
    package = pkgs.emacsGit;
    alwaysEnsure = true;
  };

in myEmacs
