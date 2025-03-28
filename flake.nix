{
  description = "a CLT to preview a collection of images, in your chosen order";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { nixpkgs, ... }:
    let
      forAllSystems = gen:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
        (system: gen nixpkgs.legacyPackages.${system});
    in {
      packages = forAllSystems (pkgs: { default = pkgs.callPackage ./. { }; });
      devShells = forAllSystems (pkgs: { default = pkgs.callPackage ./shell.nix { }; });
    };
}
