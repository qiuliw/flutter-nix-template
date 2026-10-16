{
  description = "Flutter development environment";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    nixgl = {
      url = "github:nix-community/nixGL";
      # 与 Flutter 共用 nixpkgs，避免图形库版本不一致。
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        # nixGL 匹配 NVIDIA 驱动时需要使用非自由驱动组件。
        config.allowUnfree = true;
        overlays = [ nixgl.overlays.default ];
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
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
          # 上游自动选择显卡包装器；使用 nix develop --impure 读取主机驱动信息。
          pkgs.nixgl.auto.nixGLDefault
        ];
      };
    };
}
