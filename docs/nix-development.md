# Nix 开发环境与 Linux 图形驱动

## 1. 职责划分

本模板的原则是：**项目声明依赖，主机管理硬件，社区工具处理两者的兼容。**

| 层次 | 管理者 | 内容 |
| --- | --- | --- |
| 项目开发环境 | Nix 配置 | Flutter、编译器、构建工具和开发库 |
| 图形库适配 | nixGL | 选择用户态图形库，配置加载路径，衔接主机驱动 |
| 硬件与桌面 | 主机系统 | 内核显卡驱动、GPU、Wayland/X11 桌面服务 |

项目不自行维护显卡检测、EGL 路径或驱动版本，也不默认强制软件渲染、Wayland 或关闭 Impeller。这些适合临时排障，不适合作为通用模板的兼容层。

## 2. Nix 提供开发环境，不提供运行时隔离

`nix develop` 准备工具和构建环境，例如将 Nix 提供的 Flutter、编译器加入 `PATH`，并设置开发库的查找路径。退出 shell 后，调用方的环境不会因此被改写。

但它不是容器，不会创建独立内核，也不会自动隔离文件系统、网络和设备。里面启动的程序仍是主机上的普通进程，可以在权限允许的范围内访问设备和桌面服务。

因此，应区分：

- **依赖管理**：工具和库来自哪里、使用什么版本，由 Nix 管理。
- **运行时隔离**：进程能访问什么资源，需要容器、虚拟机或额外沙箱机制。

Nix 的构建沙箱也不等于 `nix develop` 中交互程序的运行时沙箱。

本模板不会修改系统配置、shell 配置或用户 profile，但 Nix 仍会使用 `/nix/store` 和缓存；Flutter/Dart 仍可能写入用户缓存及项目的 `.dart_tool/`、`build/`。这不是“主机零写入”。

## 3. 为什么图形程序需要 nixGL

显卡驱动分为用户态和内核态两部分：

```text
Flutter 桌面进程
    ↓
OpenGL / EGL 与厂商用户态驱动库
    ↓ 通过设备节点和系统调用
主机内核中的显卡驱动
    ↓
GPU
```

应用还会通过 Wayland/X11 与主机桌面服务通信。

Nix 中的程序可以访问主机设备，但不一定能找到正确的用户态图形库：Nix 的库通常位于 `/nix/store`，主机发行版的库通常位于 `/usr/lib`。尤其是 NVIDIA，用户态组件通常需要匹配正在运行的内核驱动版本。

**nixGL 是启动包装器，不是新驱动，也不拦截每次图形调用。** 它选择并准备适用的用户态库，设置动态库搜索路径、EGL 厂商配置等环境变量，然后启动目标程序。这些环境由目标程序及其子进程继承。

它不一定直接复用主机的 `.so` 文件；例如 NVIDIA 路径会根据主机驱动版本准备匹配的组件。内核驱动仍由主机管理，nixGL 不安装或替换它。

## 4. 本模板如何接入社区实现

`flake.nix` 只保留三项关键声明：

| 配置 | 作用 |
| --- | --- |
| `inputs.nixgl.inputs.nixpkgs.follows = "nixpkgs"` | 让 nixGL 的 nixpkgs 输入跟随项目，避免另用一套版本 |
| `overlays = [ nixgl.overlays.default ]` | 将上游 nixGL 包接入本地的 `pkgs` 软件包集合 |
| `pkgs.nixgl.auto.nixGLDefault` | 在开发 shell 中提供上游自动选择的 `nixGL` 命令 |

`overlay` 是扩展或替换 Nix 软件包集合的机制，不是系统插件安装；这里只影响当前配置中的 `pkgs`。`allowUnfree` 用于允许求值和构建 NVIDIA 非自由用户态组件，也不等于安装主机驱动。

标准用法：

```sh
nix develop --impure
flutter pub get
nixGL flutter run -d linux
```

自动选择需要在 Nix 求值阶段读取主机驱动信息，因此进入环境和执行 `nix flake check` 时使用 `--impure`。它允许求值依赖主机信息，**不是授予修改系统配置的权限**。

图形环境由 nixGL 包装器在启动目标命令时设置；`flutter analyze`、`flutter test` 等普通开发命令不需要经它包装。

## 5. 可复现性与兼容性边界

- `flake.lock` 固定 Nix 输入，Flutter 项目依赖另由 `pubspec.lock` 记录；它们不锁定主机内核、显卡驱动或桌面会话。
- nixGL 的自动 NVIDIA 路径依赖主机驱动版本，首次使用或驱动更新后可能需要下载匹配组件。不能把输入已锁定理解为整个图形运行环境完全固定。
- 使用同一份 nixpkgs 可减少库版本不一致，但不能保证所有主机的图形兼容性，也不能保证硬件加速。
- 当前锁定的 nixGL 版本存在新版 NVIDIA 驱动格式识别问题（[上游 #220](https://github.com/nix-community/nixGL/issues/220)）。本机已验证可经 Mesa 路径启动和交互，未验证 NVIDIA 硬件加速。窗口正常显示不等于 GPU 加速正常。

遇到兼容问题，优先跟踪、更新社区适配层，而不是在模板中叠加主机专用补丁。

## 参考资料

- [nix develop：开发环境](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-develop.html)
- [Nixpkgs overlays：扩展软件包集合](https://nixos.org/manual/nixpkgs/stable/#chap-overlays)
- [nix-community/nixGL：图形驱动包装器](https://github.com/nix-community/nixGL)
- [NixOS Wiki：Flutter 开发](https://wiki.nixos.org/wiki/Flutter)
