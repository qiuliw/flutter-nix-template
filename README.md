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

在项目目录启动 Linux 桌面应用（无需先进入开发 shell）：

```sh
nix run
```

也可以在 `nix develop` 内启动：

```sh
flutter-run-linux
```

可向启动器传递 Flutter 参数，例如 `nix run -- --verbose`。
启动器会在锁定的 Nix 开发环境中构建和运行当前目录的 Flutter 项目。

### Linux 图形驱动兼容与配置范围

在非 NixOS 系统上，Nix 的 OpenGL/EGL 库可能无法直接使用系统显卡驱动。
启动器使用 `flake.lock` 中同一份 nixpkgs 提供的 Mesa，无需额外运行 `nix shell nixpkgs#mesa` 或查询全局 registry。
它只在启动器及其子进程中设置以下兼容配置：

- `__EGL_VENDOR_LIBRARY_FILENAMES` 指向 Nix Mesa 的 EGL 配置。
- `LIBGL_ALWAYS_SOFTWARE=1` 启用软件渲染。
- `GDK_BACKEND=wayland` 使用 Wayland。
- Flutter 启动时附带 `--enable-software-rendering --no-enable-impeller`。

此启动器要求已有可用的 Wayland 桌面会话，软件渲染不代表硬件加速已配置。
`nix develop` 本身不会设置上述图形变量，普通 `flutter` 命令也不会被替换；
显卡驱动已兼容时仍可直接使用 `flutter run -d linux`。

这些配置不会写入系统目录、shell 配置或用户 profile，不使用 `nix profile install`。
**Nix 不是容器或零写入沙箱**：Nix 仍会写入 `/nix/store`、维护缓存和 GC roots；
Flutter/Dart 也可能写入用户缓存，以及项目内的 `.dart_tool/`、`build/` 等生成目录。
应用运行时仍连接主机的桌面服务。若要求完全不写主机缓存或更强的运行时隔离，应使用虚拟机或另外配置的容器环境。

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
