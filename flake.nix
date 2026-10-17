{
  description = "Flutter development environment";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      # inputs.nixpkgs.follows = "nixpkgs"; # 复用 nixpkgs
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem = { pkgs, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          # nixGL 匹配 NVIDIA 驱动时需要使用非自由驱动组件。
          config.allowUnfree = true;
          overlays = [ inputs.nixgl.overlays.default ];
        };

        devShells.default = pkgs.mkShell {
          # 使用匹配的桌面 schema，避免继承主机或 Snap 的不兼容版本。
          GSETTINGS_SCHEMA_DIR = pkgs.glib.getSchemaPath pkgs.gsettings-desktop-schemas;

          packages = with pkgs; [
            flutter
            # Linux 桌面构建所需的编译工具和图形库。
            clang
            cmake
            ninja
            pkg-config
            gtk3
            libGL
            libepoxy
            # 自动选择显卡包装器；使用 nix develop --impure 读取主机驱动信息。
            nixgl.auto.nixGLDefault
          ];
        };
      };
    };
}
