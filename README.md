# Flutter Nix Template

使用 Nix Flakes 管理 Flutter 开发环境，通过社区 [nixGL](https://github.com/nix-community/nixGL) 处理 Linux 显卡兼容。

## 开始使用

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
