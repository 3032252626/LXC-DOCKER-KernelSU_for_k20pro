# LXC-DOCKER-KernelSU_for_k20pro

基于 GitHub Actions 的安卓内核自动编译仓库，面向红米 K20 Pro（raphael，4.14 非 GKI）编译集成 KernelSU + LXC/Docker 的内核，支持 Droidspaces 容器场景。fork 自 [wu17481748/LXC-DOCKER-KernelSU_Action](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)。

> **声明**：本仓库工作流体系源自上游社区，编译适配、问题排查与修复由 AI 辅助完成。

### 实测环境

| 项目 | 说明 |
|------|------|
| 设备 | Redmi K20 Pro 尊享版（raphael，4.14 非 GKI 内核） |
| 内核 | `4.14.357-Zundamon-v4.1-LXC`（oss-base 分支） |
| 容器 | Droidspaces |
| 管理器 | KernelSU 非 GKI 版（官方 v0.9.5 或 rsuntk legacy） |

### KernelSU 非 GKI 适配说明

KernelSU 官方自 v1.0 起放弃非 GKI 内核支持。本仓库工作流通过官方 [tiann/KernelSU](https://github.com/tiann/KernelSU) 的 `setup.sh` 集成 **v0.9.5**（最后支持非 GKI 的官方版本）。

如需新版 v3.x 协议（支持 Android 16 等），可改用社区维护的 [rsuntk/KernelSU](https://github.com/rsuntk/KernelSU) backport fork（持续 backport 至 4.4~6.18 内核），注入 legacy tag 并配套使用 rsuntk legacy 管理器。

> **注意**：非 GKI 设备切勿使用 rsuntk 的 `main` 分支注入（其跟随官方 v3.x GKI 代码），否则编出的 KSU 模块无法被任何管理器识别。

---

## 一、项目介绍

本仓库提供 4 个 GitHub Actions 工作流，一键编译支持 LXC/Docker 容器 + KernelSU 的安卓内核（4.14）。

### 引用的补丁与脚本（编译时从上游拉取）

| 文件 | 来源 | 用途 |
|------|------|------|
| `LXC-DOCKER-OPEN-CONFIG.sh` | [android-lxc-docker](https://github.com/3032252626/android-lxc-docker) | LXC/Docker 内核配置注入 |
| `xt_qtaguid.patch` | 同上 | qtaguid 网络模块补丁 |
| Droidspaces Non-GKI 补丁 01/02 | [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) | Non-GKI xt_qtaguid panic 修复 + cgroup 文件前缀处理 |
| `setup.sh` (v0.9.5) | [tiann/KernelSU](https://github.com/tiann/KernelSU) | KernelSU 驱动集成（最后非 GKI 官方版） |
| keepalive.c（内嵌） | 工作流内置 heredoc | 内核级防息屏冻结（仅 Droidspaces 方案1 工作流） |

---

## 二、快速开始

1. Fork 本仓库
2. 编辑 `config.env` 按需修改后 Commit
3. Actions → 选择对应工作流 → Run workflow
4. 编译完成后从 Artifacts 下载 AnyKernel3 刷入包

**所有工作流共享同一份 `config.env` 与同一内核源码/编译器环境**，差异仅在 KernelSU 集成方式与是否注入 Droidspaces 优化，选一个合适的即可。

---

## 三、工作流总览

| 工作流 | 名称 | 适用场景 | 推荐度 |
|--------|------|----------|--------|
| `build-AB-clang14.yml` | 高端机 谷歌clang14 [方案1-kprobe] | 常规内核，LXC/Docker + KernelSU | 常规可选 |
| `build-AB-clang14-plan2.yml` | 高端机 谷歌clang14 [方案2-手动源码补丁] | 常规内核，KernelSU 手动源码集成 | 常规可选 |
| `build-droidspaces-clang14.yml` | Droidspaces Non-GKI 谷歌clang14 [方案1-kprobe] | **Droidspaces 容器主力**，含防息屏冻结 | **推荐** |
| `build-droidspaces-clang14-plan2.yml` | Droidspaces Non-GKI 谷歌clang14 [方案2-手动源码补丁] | Droidspaces，KernelSU 手动源码集成 | 备选 |

---

## 四、工作流逐一介绍

### 1. build-AB-clang14.yml —— 常规编译（方案1-kprobe）

- 编译器：Google clang 14（AOSP android13-release / clang-r450784d）
- KernelSU：`setup.sh` 注入 v0.9.5 + 开启 kprobe 配置（`CONFIG_KPROBES` 等）
- 特色：LXC/Docker 配置注入时先清理 `CONFIG_PID_NS` / `CONFIG_BRIDGE_NETFILTER` 重复项再写入，并追加 IP6 / NF_TABLES 相关配置，避免脚本报 "appears more than once"
- 可选：`ENABLE_KVM` 开启 KVM、`ENABLE_PATH_UMOUNT` 注入 path_umount
- 产物：`Image.gz-dtb`（AnyKernel3 刷入包）

### 2. build-AB-clang14-plan2.yml —— 常规编译（方案2-手动源码补丁）

- 与工作流 1 环境相同，差异仅在 KernelSU 集成：不开 kprobe，改为**手动源码补丁**方案
- 通过内嵌 Python 脚本对 `fs/exec.c`、`fs/open.c`、`fs/read_write.c`、`fs/stat.c` 注入 KSU 回调，并启用 `CONFIG_KSU`
- 适用：内核未开启 kprobe 或 kprobe 方案不适配时使用

### 3. build-droidspaces-clang14.yml —— Droidspaces 主力（方案1-kprobe，推荐）

在常规编译基础上额外注入 **Non-GKI 容器必需的配置与修复**，是 Droidspaces 容器场景的主推工作流：

- **防息屏冻结**（`ENABLE_KEEPALIVE=true` 时）：以 heredoc 内嵌方式写入内核驱动 `drivers/misc/keepalive.c` 并挂入 Makefile 编译，注册 wakeup source 使内核不自动 suspend，从根上解决容器息屏后 CPU 冻结、定时任务不触发的问题；注入后回显验证，杜绝静默失败
- **Non-GKI 配置补充**：批量追加 `CONFIG_SYSVIPC`、`CONFIG_DEVTMPFS`、`CONFIG_OVERLAY_FS`、cgroup、netfilter 等 Droidspaces 致命依赖配置（已存在则跳过）
- **Non-GKI 官方补丁**：应用 Droidspaces-OSS 的 xt_qtaguid panic 修复 + cgroup 文件前缀处理两个补丁
- KernelSU：方案1（kprobe v0.9.5）

### 4. build-droidspaces-clang14-plan2.yml —— Droidspaces 备选（方案2-手动源码补丁）

- 与工作流 3 相比：包含相同的 Non-GKI 配置补充与官方补丁，但 KernelSU 采用方案2手动源码补丁（`CONFIG_KSU`），**不注入防息屏冻结驱动**
- 仅在需要方案2 的 KSU 集成方式时选用

> **选型建议**：Droidspaces 场景直接用 **工作流 3**；如需 KSU 方案2则用工作流 4。常规内核（不跑容器）用工作流 1/2。

---

## 五、config.env 配置说明（当前完整变量）

| 变量 | 说明 | 当前值 |
|------|------|--------|
| `KERNEL_SOURCE` | 内核源码仓库 | `https://github.com/3032252626/kernel_xiaomi_raphael` |
| `KERNEL_SOURCE_BRANCH` | 内核源码分支 | `oss-base` |
| `KERNEL_CONFIG` | defconfig 文件名 | `raphael_defconfig` |
| `KERNEL_ZIP_NAME` | 产物 zip 命名 | `raphael_Zundamon-v4.1-LXC-KernelSU-rsuntk` |
| `KERNEL_IMAGE_NAME` | 打包的内核镜像 | `Image.gz` |
| `ENABLE_KVM` | 是否开启 KVM | `false` |
| `ENABLE_LXC_DOCKER` | 是否开启 LXC/Docker | `true` |
| `ENABLE_KEEPALIVE` | 是否启用防息屏冻结驱动（仅 Droidspaces 方案1 工作流读取） | `true` |
| `LLVM_CONFIG` | 是否启用 LLVM=1 / LLVM_IAS=1 | `n` |
| `SWITCH_PYTHON` | 是否切换 python2（一般不需要） | `false` |
| `NEED_DTBO` | 是否需要 dtbo（一般不需要） | `false` |
| `ENABLE_KERNELSU` | 是否集成 KernelSU | `true` |
| `KERNELSU_TAG` | KernelSU 注入参考标签（实际注入版本以工作流内 `bash -s` 为准） | `main` |
| `ENABLE_PATH_UMOUNT` | 是否启用 path_umount | `true` |

> 注：工作流内 KernelSU 注入命令固定为 `bash -s v0.9.5`，`KERNELSU_TAG` 仅作记录参考；如需更换注入版本（如改用 rsuntk legacy），须直接修改工作流中对应 `curl | bash -s <tag>` 一行。

---

## 六、常见编译问题

### DTC 链接报 yaml 未定义

```bash
sed -i 's/HOSTLDLIBS_dtc/HOSTLOADLIBES_dtc/g' scripts/dtc/Makefile
```

### struct timespec 与 timespec64 不兼容

```bash
sed -i 's/struct timespec now = current_time/struct timespec64 now = current_time/' fs/btrfs/inode.c fs/btrfs/file.c
```

### arch/arm64/mm/hugetlbpage.c 编译报错

```bash
sed -i 's/ptep = huge_pmd_share/pte = huge_pmd_share/' arch/arm64/mm/hugetlbpage.c
```

### AnyKernel3 刷入报 "Unable to determine boot partition"

sed 必须匹配大写 `BLOCK=`：

```bash
sed -i 's!BLOCK=/dev/block/platform/omap/omap_hsmmc.0/by-name/boot;!BLOCK=/dev/block/bootdevice/by-name/boot;!g' AnyKernel3/anykernel.sh
```

### Droidspaces 容器启动失败

确认内核已开启 `CONFIG_SYSVIPC=y` 和 `CONFIG_DEVTMPFS=y`。这两个是 Droidspaces 致命依赖，缺失需重编译内核。

### KernelSU 管理器报"只支持 GKI 内核"

- 官方 tiann 管理器 v3.x 仅支持 GKI，非 GKI 设备请使用 v0.9.5 内核 + v0.9.5 管理器，或改用 rsuntk legacy 内核 + legacy 管理器
- 自编译非 GKI 内核必须用 rsuntk 的 **legacy tag** 注入（如 `bash -s v3.2.2-10-legacy`），不可用 `main` 分支
- 排查时优先看管理器显示的 KSU 驱动版本号，而非内核 uname：v0.9.5 特征为驱动版本 11872，rsuntk legacy 特征为 32447

---

## 七、KernelSU 双方案说明

| 方案 | 原理 | 优缺点 |
|------|------|--------|
| 方案1 - kprobe | 依赖 `CONFIG_KPROBES`，KernelSU 自动注入 hook | 简洁，但需要内核开启 kprobe |
| 方案2 - 手动源码补丁 | 直接修改 `fs/exec.c`/`fs/open.c`/`fs/read_write.c`/`fs/stat.c` 注入 KSU 回调 | 不依赖 kprobe，兼容性更好 |

---

## 八、致谢

- [AnyKernel3](https://github.com/osm0sis/AnyKernel3)
- [AOSP](https://android.googlesource.com)
- [KernelSU](https://github.com/tiann/KernelSU)（非 GKI 兼容由 [rsuntk/KernelSU](https://github.com/rsuntk/KernelSU) 提供）
- [wu17481748](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)
- [ego-taboo](https://github.com/ego-taboo)
- [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS)
- [xiaoleGun](https://github.com/xiaoleGun/KernelSU_Action)
- [xiaoxindada](https://github.com/xiaoxindada)
