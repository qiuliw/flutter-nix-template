{
  description = "Flutter development environment";

  inputs.nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      linuxRunner = pkgs.writeShellApplication {
        name = "flutter-run-linux";
        runtimeInputs = [ pkgs.flutter ];
        text = ''
          if [[ ! -f pubspec.yaml ]]; then
            printf '%s\n' 'Run this command from your Flutter project directory.' >&2
            exit 1
          fi
          if [[ -z "''${WAYLAND_DISPLAY:-}" ]]; then
            printf '%s\n' 'This software-rendering launcher requires a Wayland desktop session.' >&2
            exit 1
          fi

          export __EGL_VENDOR_LIBRARY_FILENAMES="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
          export LIBGL_ALWAYS_SOFTWARE=1
          export GDK_BACKEND=wayland
          exec flutter run -d linux --enable-software-rendering --no-enable-impeller "$@"
        '';
      };
      appRunner = pkgs.writeShellApplication {
        name = "run-flutter";
        runtimeInputs = [ pkgs.nix ];
        text = ''
          exec nix develop path:${self} --command ${linuxRunner}/bin/flutter-run-linux "$@"
        '';
      };
    in
    {
      packages.${system}.default = appRunner;
      apps.${system}.default = {
        type = "app";
        program = "${appRunner}/bin/run-flutter";
        meta.description = "Run Flutter on Wayland with project-pinned Mesa software rendering";
      };

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
          mesa
          linuxRunner
        ];
      };
    };
}
