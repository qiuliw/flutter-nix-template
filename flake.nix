{
  description = "Flutter development environment";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ nixgl.overlays.default ];
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          flutter
          clang
          cmake
          ninja
          pkg-config
          gtk3
          libGL
          libepoxy
          pkgs.nixgl.auto.nixGLDefault
        ];
      };
    };
}
