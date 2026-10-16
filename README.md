# Flutter Nix Template

使用 Nix Flakes 管理开发环境的 Flutter 项目模板，包含默认计数器示例。

## 使用模板

在 GitHub 上点击 **Use this template → Create a new repository**，然后克隆新仓库。
本地需要安装 Nix，并启用 `nix-command` 和 `flakes` 实验特性。

模板默认项目名为 `flutter_app`，应用标识前缀为 `com.example`；开发自己的应用前请按需修改项目名和各平台的应用标识。

## Nix 开发环境

在项目目录执行：

```sh
nix develop
flutter pub get
flutter analyze
flutter test
```

运行 Linux 桌面应用：

```sh
flutter run -d linux
```

### Linux 图形驱动兼容

在非 NixOS 系统上，Nix 的 OpenGL/EGL 库可能无法直接使用系统显卡驱动。
若遇到 `No provider of eglGetPlatformDisplayEXT found` 等错误，可在 Wayland 桌面尝试以下已验证的软件渲染方式：

```sh
nix shell nixpkgs#mesa --command bash -c '
  export __EGL_VENDOR_LIBRARY_FILENAMES="$(nix eval --raw nixpkgs#mesa.outPath)/share/glvnd/egl_vendor.d/50_mesa.json"
  export LIBGL_ALWAYS_SOFTWARE=1
  export GDK_BACKEND=wayland
  nix develop --command flutter run -d linux --enable-software-rendering --no-enable-impeller
'
```

软件渲染用于兼容性回退，不代表硬件加速已配置；上述命令要求当前会话支持 Wayland。

### Web

也可以通过浏览器访问 Web 版本：

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

`flake.lock` 固定 Nix 依赖版本，当前开发环境面向 `x86_64-linux`，包含 Flutter 和 Linux 桌面构建工具。
Android/iOS 目录已生成，但相应 SDK、模拟器或 Xcode 仍需另外配置；iOS 构建需要 macOS。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
