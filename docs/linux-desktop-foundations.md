# 从 nixGL 到 Linux 桌面应用基建

Linux 桌面应用不仅需要可执行文件，还依赖动态库、图形驱动、桌面服务和配置资源。理解这些边界，比针对每条报错叠加环境变量更有效。

## 1. 先区分几套机制

| 机制 | 解决的问题 | 典型组件 |
| --- | --- | --- |
| 构建 | 源码如何变成程序 | 编译器、链接器、CMake、Flutter 工具 |
| 动态库加载 | 进程从哪里取得运行代码 | ELF 加载器、共享库、RPATH/RUNPATH |
| 应用基础设施 | 如何处理事件、对象、文件与设置 | GLib、GObject、GIO |
| 内容绘制 | 控件、文字如何变成像素 | GTK、Flutter 引擎、Pango、Cairo、图形 API |
| 窗口与显示 | 如何呈现窗口、协调输入和屏幕输出 | Wayland/X11、合成器、内核显示驱动 |

这些机制相互协作，但不是一条固定的长调用链。schema 不是驱动，GTK 不是桌面合成器，nixGL 也不是整个桌面的兼容层。

## 2. 应用、用户态库与内核驱动

### 用户态库

GTK、GLib、OpenGL/EGL 加载器、厂商图形实现等，通常以共享库的形式加载到应用进程中，不一定各自运行一个服务。

动态加载器根据依赖声明、RPATH/RUNPATH、环境变量等规则寻找库；插件也可能在运行中动态加载。找到文件之后，还需要满足 ABI，即符号、参数传递和数据布局等二进制接口约定。

不同版本的库可以兼容。只有实际加载的组合不兼容，例如某图形库需要当前进程无法提供的 glibc 符号，才会产生问题。

### 内核驱动

以常见的 GPU 渲染路径为例：

```text
应用进程
  └─ 用户态图形库
       └─ 通过设备节点和系统调用
            └─ 主机内核显卡驱动
                 └─ GPU
```

用户态驱动负责图形 API 的实现及工作提交，内核驱动提供受控的硬件访问等能力；显示控制还涉及 DRM/KMS。软件渲染则可能不使用 GPU 完成绘制。

两层需要兼容，但匹配规则因驱动而异。NVIDIA 通常要求用户态组件与正在运行的内核驱动版本匹配；不能把这个要求泛化为所有 Mesa 组件必须与内核版本一一对应。

**驱动软件可以由 Nix 管理。** NixOS 本身就管理内核与图形驱动。在其他发行版上使用 Nix 开发环境，通常是 Nix 提供用户态库，主机提供正在运行的内核驱动，而不是项目 shell 替换主机驱动。

## 3. nixGL 的位置

nixGL 主要用于帮助非 NixOS 系统上的 Nix 图形程序获得合适的驱动加载环境。

```sh
nixGL application [arguments]
```

其工作分为两部分：

1. **准备包装器**：自动入口可读取主机驱动信息，选择并准备适用的用户态组件。
2. **启动命令**：包装脚本设置图形库搜索路径、EGL 厂商配置等环境，再通过 `exec` 执行目标命令。

之后由应用加载图形库、初始化图形上下文并渲染。nixGL 不在每次图形调用之间转发，也不是先创建一个“驱动空间”交给应用。

```text
nixGL 配置加载环境
  → 启动目标命令
  → 应用加载图形库并调用
  → 图形库与主机内核驱动交互
```

nixGL 不一定直接使用主机 `/usr/lib` 的库。Mesa 路径可以使用 Nix 提供的 Mesa；NVIDIA 路径可以根据主机版本准备匹配的用户态组件。简单追加系统库路径，并不能保证动态链接兼容。

OpenGL 和 Vulkan 有不同包装入口，不能假定某一个入口配置了全部图形 API。nixGL 也不负责 GTK 设置、主题、输入法、内核驱动安装或运行时隔离。

## 4. GLib、GObject、GIO 与 GTK

| 组件 | 职责 |
| --- | --- |
| GLib | 数据结构、事件循环、线程等基础设施 |
| GObject | 类型、对象、属性、信号与引用计数 |
| GIO | 文件与流、异步操作、D-Bus、GSettings 等 |
| GTK | 窗口、控件、布局、输入及桌面集成 |
| GDK | GTK 与窗口系统、输入和显示能力之间的抽象 |

GLib 不等于 glibc：后者是 GNU C 标准库。GLib/GIO 也可用于非图形程序。

GTK 与其他组件共同完成界面工作，例如 Pango 负责文字排版，Cairo 提供绘制能力。GTK 3 与 GTK 4 的渲染架构不同，GTK 4 还包含 GSK；不能用一条固定流水线概括所有版本。

GTK 是工具包，GNOME 是桌面环境。GTK 应用不必运行在 GNOME 下，也可以与其他工具包的应用共存。

Flutter Linux 应用通常使用 GTK 嵌入层处理窗口和平台集成，而 Flutter 页面控件主要由 Flutter 引擎绘制，并非逐个转换为 GTK 控件。

## 5. GSettings、schema 与用户设置

| 概念 | 含义 |
| --- | --- |
| schema | 设置项的定义：键名、类型、默认值、范围或枚举 |
| GSettings | 读取、写入和监听设置的 API，属于 GIO |
| 后端，如 dconf | 保存用户实际选择的值；未覆盖时使用默认值 |

schema 通常以 `.gschema.xml` 编写，用 `glib-compile-schemas` 编译成 `gschemas.compiled`，供程序运行时读取。

例如：schema 规定“某字体设置是枚举，默认 grayscale”，用户设置保存“我选 rgba”。**设置定义与设置值是两回事。** schema 不绘制像素，也不是显卡配置。

GTK 初始化时可能读取字体等桌面偏好，运行期间也可能监听变化。schema 缺失、键不存在或类型不符合预期，都可能导致设置读取失败；是否致命取决于具体调用路径。

### 为什么使用 Nix 库，还可能读到外部 schema？

动态库加载与配置资源搜索是两套机制。即使 GTK/GLib 来自 `/nix/store`，schema 路径仍可能继承自主机、IDE 或 Snap 环境。

**使用 Nix 的 GTK/GLib 时，优先使用兼容的 Nix schema，能减少环境混搭；这不要求用户实际的设置值也迁入 Nix。** 系统 schema 若兼容，同样可以使用。

开发 shell 可以明确指定：

```nix
GSETTINGS_SCHEMA_DIR = pkgs.glib.getSchemaPath pkgs.gsettings-desktop-schemas;
```

它让 GLib 优先查找该 Nix 包中的 schema，不修改用户偏好，也不完全禁止其他来源的 schema。`gsettings-desktop-schemas` 提供通用桌面定义，不包含所有应用的 schema。

正式打包 GTK 程序时，Nixpkgs 的 `wrapGAppsHook` 系列可参与配置资源环境；把 hook 加进交互 shell，不等于之后生成的每个可执行文件都自动获得包装。

## 6. 绘制、窗口与屏幕显示

- **应用**：布局界面，使用 CPU 或 GPU 绘制到缓冲区。
- **Wayland**：应用与合成器之间的协议，承载 surface、缓冲区提交和输入等信息，不是渲染引擎。
- **合成器**：组织可见窗口、协调输入并提交显示。GNOME 常用 Mutter，KDE 常用 KWin。
- **内核显示接口与硬件**：参与显示模式控制和最终输出。

Wayland 下通常由应用绘制内容、合成器组织呈现；直接扫描输出等优化可能省去一次合成。现代 X11 也支持应用直接渲染，不能简单理解为“X11 服务器画，Wayland 客户端画”。

字体设置影响“如何绘制”，图形库负责“执行绘制”，显示系统负责“如何呈现”。它们不是同一个职责。

## 7. Nix 管理的边界

`nix develop` 准备工具和构建环境，但其中的应用通常仍是主机普通进程：使用主机内核、设备和桌面服务，并继承部分父进程环境。

需要区分：

- **开发环境**：工具、头文件和库的配置。
- **构建沙箱**：构建时的资源访问限制。
- **纯求值**：限制 Nix 表达式依赖可变外部状态。
- **运行时隔离**：应用运行时的文件、网络、设备权限边界。

它们不是同一件事。`--impure` 允许求值读取主机等外部信息，不是 root 权限开关，也不是所有开发环境都需要它。

### 配置中的几个概念

| 名称 | 含义 |
| --- | --- |
| nixpkgs | 软件包定义的来源 |
| pkgs | 按平台、选项和 overlay 导入后的包集合 |
| overlay | 向包集合添加或覆盖属性 |
| follows | 复用另一个 Flake 输入，不再独立锁定一份输入 |
| flake-parts | 用模块系统组织各平台输出 |
| `_module.args.pkgs` | 为模块提供定制的包集合参数 |

Nix 允许多版本依赖共存，相同 store 路径也不会重复存储。不设置 `follows` 不等于必然冲突；它主要统一输入。混合图形栈时，共用包集合能减少未经验证的库组合，但不能作为兼容性证明。

锁文件不固定整台机器：主机内核、驱动和桌面会话仍可能变化，自动检测和外部下载也可能引入额外条件。Nix/Flutter 仍使用 store、缓存和构建目录。**依赖可复现不等于零写入、运行隔离或可随意复制分发。**

## 8. 按层定位故障

| 现象 | 优先检查 |
| --- | --- |
| 编译、链接失败 | SDK 约束、头文件、构建工具、缓存 |
| 共享库 not found | ELF 依赖、加载器、RPATH/RUNPATH |
| EGL provider 或上下文失败 | 用户态图形实现、驱动发现、主机接口 |
| schema 或 key 错误 | 设置定义的来源、版本和搜索优先级 |
| 仅某个终端失败 | IDE/Snap/嵌套 shell 继承的变量与资源路径 |

排查顺序：**找首条实际错误 → 判断所属层 → 对比成功与失败环境 → 一次改变一个条件 → 验证真实运行。** 最后的“调试连接失败”通常只是应用提前退出的结果。

可用 `readelf -d` 检查 ELF 依赖和运行路径；对可信本地构建产物，可用 `ldd` 辅助检查。切换 SDK 或编译环境后，旧 CMake 缓存可能保留过期选项，干净构建比直接堆加载路径更有诊断价值。

需要分别验证：依赖可构建、窗口可显示和交互、预期 GPU 确实加速。软件渲染也能呈现正常窗口。

## 9. 开发成功不等于完成分发

开发 shell 中能运行，不代表离开 shell 仍可运行；本机可运行，也不代表复制到另一台机器即可运行。

正式交付要处理依赖闭包、资源文件、schema、启动包装器和运行时服务。Nix 构建产物可能依赖 store 路径；Flutter 等应用通常要保留完整资源目录。Nix 包、Flatpak、AppImage 等交付方式各有不同边界。

**nixGL 解决图形库与主机驱动的一部分衔接，不代替完整的桌面应用打包。**

## 参考资料

- [nix-community/nixGL](https://github.com/nix-community/nixGL)
- [GTK 3](https://docs.gtk.org/gtk3/) / [GTK 4](https://docs.gtk.org/gtk4/)
- [GLib](https://docs.gtk.org/glib/) / [GObject](https://docs.gtk.org/gobject/) / [GIO](https://docs.gtk.org/gio/)
- [GSettings](https://docs.gtk.org/gio/class.Settings.html)
- [Wayland 架构](https://wayland.freedesktop.org/architecture.html)
- [nix develop](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-develop.html)
- [Nixpkgs overlays](https://nixos.org/manual/nixpkgs/stable/#chap-overlays)
- [NixOS Graphics](https://wiki.nixos.org/wiki/Graphics)
