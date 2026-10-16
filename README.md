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

## 配置说明

- Flutter、构建工具和 nixGL 都在 `flake.nix` 声明，Nix 输入由 `flake.lock` 锁定。
- 直接使用 nixGL 上游的自动选择包装器；`--impure` 用于读取主机显卡驱动信息，不是向系统安装配置。
- NVIDIA 首次使用或主机驱动更新后可能需要下载匹配的驱动组件。锁文件不锁定主机驱动。
- 上游存在新版 NVIDIA 驱动识别问题（[nixGL #220](https://github.com/nix-community/nixGL/issues/220)）；当前主机实测可经 Mesa 路径启动，但未验证 NVIDIA 硬件加速。
- 不修改系统、shell 配置或用户 profile；Nix/Flutter 仍使用 store、缓存和项目构建目录，不等于容器隔离。
- 默认项目名为 `flutter_app`，应用标识前缀为 `com.example`，请按需修改。
- 各平台工程已生成，但 Android SDK、模拟器和 Xcode 需另行配置；iOS/macOS 构建需要 macOS。

Flutter 文档：[docs.flutter.dev](https://docs.flutter.dev/)。
