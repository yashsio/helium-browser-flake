{
  description = "Helium - private, fast, and honest web browser (Chromium-based)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system: {
        helium = nixpkgs.legacyPackages.${system}.callPackage ./helium.nix { };
        default = self.packages.${system}.helium;
      });

      apps = forAllSystems (system: {
        helium = {
          type = "app";
          program = "${self.packages.${system}.helium}/bin/helium";
          meta.description = "Run Helium, the private Chromium-based web browser";
        };
        default = self.apps.${system}.helium;
      });

      overlays.default = final: prev: {
        helium = final.callPackage ./helium.nix { };
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
