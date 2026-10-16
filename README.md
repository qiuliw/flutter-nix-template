# Flutter Nix Template

使用 Nix Flakes 管理 Flutter 开发环境，通过社区 [nixGL](https://github.com/nix-community/nixGL) 处理 Linux 显卡兼容，不维护自定义图形启动器。

## 开始使用

点击 **Use this template → Create a new repository**，克隆新仓库后在项目目录运行：

```sh
nix develop --impure
flutter pub get
nixGL flutter run -d linux
```

需要安装 Nix 并启用 `nix-command`、`flakes`，当前环境支持 `x86_64-linux`。桌面运行需要可用的图形会话。

## 常用命令

在开发 shell 内执行：

```sh
flutter analyze
flutter test
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

检查 Nix 配置：

```sh
nix flake check --impure
```

## 使用边界

- 默认项目名为 `flutter_app`，应用标识前缀为 `com.example`，请按需修改。
- 各平台工程已生成，但 Android SDK、模拟器和 Xcode 需另行配置；iOS/macOS 构建需要 macOS。
- Nix 不等于容器隔离；当前 nixGL 还有新版 NVIDIA 驱动识别限制，启动成功不代表 NVIDIA 硬件加速正常。

## 原理文档

[Nix 开发环境与 Linux 图形驱动](docs/nix-development.md)：集中说明开发环境、驱动分层、nixGL、overlays、`--impure` 及可复现性的边界。

Flutter 文档：[docs.flutter.dev](https://docs.flutter.dev/)。
