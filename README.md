# LXC-DOCKER-KernelSU_Action

基于 GitHub Actions 的安卓内核自动编译工具，集成 KernelSU 与 LXC/Docker 支持。fork 自 [wu17481748/LXC-DOCKER-KernelSU_Action](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)。

> **声明**：本仓库工作流及补丁体系均源自上游社区，未进行自主开发维护。编译适配、问题排查与修复均由 AI 辅助完成。

> **当前状态（2026-09-18 更新）**：已从 4.14 非 GKI 内核迁移到 **5.4.302 GKI 内核**（fork 自 HeliumStudio-Dev/kernel_xiaomi_raphael-5.4）。5.4 内核已内置 KernelSU（backslashxx/KernelSU v3.2.5+），无需 setup.sh 注入。以下文档中标注 `[4.14遗留]` 的内容仅供历史参考，不适用于当前 5.4 编译。

### 实测环境

| 项目 | 说明 |
|------|------|
| 设备 | Redmi K20 Pro（raphael，骁龙855 sm8150） |
| 当前内核 | `5.4.302-GKI-Zundamon-NEXT-v1.0-alpha3` |
| ROM | SOVIET-ANDROID 16.0（HyperOS 4，Android 17） |
| 容器 | Droidspaces（Debian13）+ LXC/Docker |
| KernelSU | 内核内置（backslashxx/KernelSU v3.2.5+），管理器需对应版本 |

---

## 一、项目介绍

本仓库提供 GitHub Actions 工作流，一键编译支持 LXC/Docker 容器的安卓内核。

### 内核版本

`5.4.302 GKI`（zundamon-miui-5.4 分支）

### 补丁与脚本

| 文件 | 来源 | 用途 |
|------|------|------|
| `LXC-DOCKER-OPEN-CONFIG.sh` | [android-lxc-docker](https://github.com/3032252626/android-lxc-docker) | LXC/Docker 内核配置注入 |
| `xt_qtaguid.patch` | 同上 | qtaguid 网络模块补丁 |
| Droidspaces 补丁 01/02 | [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) | Non-GKI xt_qtaguid panic 修复 + cgroup 前缀处理 |
| `runcpatch.sh` | 同上 scripts-legacy/ | runc cgroup 兼容补丁 |
| `clangfix2.sh` | 同上 scripts-legacy/ | clang Makefile 兼容修复 |

---

## 二、快速开始

1. **Fork 本仓库**
2. **编辑配置** — `config.env` 按需修改后 Commit
3. **选择工作流** — Actions → 选择对应工作流
4. **触发编译** — Run workflow
5. **下载产物** — 从 Artifacts 下载 AnyKernel3 刷入包

---

## 三、config.env 配置说明

| 变量 | 说明 | 当前值 |
|------|------|--------|
| `KERNEL_SOURCE` | 内核源码仓库 | `https://github.com/3032252626/kernel_xiaomi_raphael-5.4` |
| `KERNEL_SOURCE_BRANCH` | 内核源码分支 | `zundamon-miui-5.4` |
| `KERNEL_CONFIG` | defconfig 文件名 | `raphael_defconfig` |
| `KERNEL_ZIP_NAME` | 产物 zip 命名 | `raphael_Zundamon-5.4-LXC` |
| `KERNEL_IMAGE_NAME` | 打包的内核镜像 | `Image.gz`（GKI 不拼 DTB，无 Image.gz-dtb） |
| `LLVM_CONFIG` | 是否启用 LLVM=1 / LLVM_IAS=1 | `n` |
| `ENABLE_KVM` | 是否开启 KVM | `false` |
| `ENABLE_LXC_DOCKER` | 是否开启 LXC/Docker | `true` |
| `ENABLE_KERNELSU` | 是否通过 setup.sh 注入 KSU | `false`（5.4 内核已内置 KSU，无需注入） |
| `KERNELSU_TAG` | 保留备用 | `v0.9.5` |
| `ENABLE_PATH_UMOUNT` | 是否启用 path_umount | `false` |
| `SWITCH_PYTHON` | 是否切换 python2 | `false` |
| `NEED_DTBO` | 是否需要 dtbo | `false` |

---

## 四、工作流选型

### 主力编译（5.4 GKI）

| 工作流 | 编译器 | 说明 |
|--------|--------|------|
| `build-droidspaces-clang18.yml` | zyc clang 18.0.0 | **当前主力**，5.4 GKI 专用 |
| `build-AB-Mandi-Sa.yml` | Mandi-Sa clang（codeberg） | 备用，codeberg 仓库已失效 |
| `build-AB-zyc.yml` | zyc clang 18.0.0 | 备用 |

### 旧版（4.14 遗留，不适用当前内核）

| 工作流 | 编译器 | 说明 |
|--------|--------|------|
| `build-droidspaces-clang14.yml` | Google clang 14 | `[4.14遗留]` 旧 4.14 主工作流，clang14 不支持 5.4 GKI |

---

## 五、编译适配记录（5.4 GKI + clang18）

以下为从 4.14 迁移到 5.4 GKI 过程中遇到的编译错误及修复，记录备查：

### 1. `netprio_cgroup.h: no member named 'id' in 'struct cgroup'`
**原因**：`CONFIG_CGROUP_NET_PRIO=y` 导致编译 netprio_cgroup.h，但该头文件用了 `cgrp->id`，5.4 内核的 cgroup 结构体无此成员。
**修复**：在 defconfig 中显式禁用 `# CONFIG_CGROUP_NET_PRIO is not set`。

### 2. `htc_recv.c: snprintf will always be truncated [-Werror,-Wfortify-source]`
**原因**：clang18 对 WiFi 驱动的 fortify-source 检查过严，旧代码 snprintf 缓冲区太小。
**修复**：编译命令加 `KCFLAGS="-Wno-error=fortify-source"`。

### 3. `ld.lld: error: undefined symbol: probe_user_write`
**原因**：btrfs 代码 backport 不完整，引用了 `probe_user_write` 但未实现。
**修复**：禁用 BTRFS（`# CONFIG_BTRFS_FS is not set`），LXC/Docker 不需要 btrfs。

### 4. AnyKernel3 刷入报 "Unable to determine boot partition"
**原因**：上游 AnyKernel3 的 anykernel.sh 用大写 `BLOCK=` 和 `IS_SLOT_DEVICE=`，sed 必须匹配大写。
**修复**：
```bash
sed -i 's!BLOCK=/dev/block/platform/omap/omap_hsmmc.0/by-name/boot;!BLOCK=auto;!g' AnyKernel3/anykernel.sh
sed -i 's/IS_SLOT_DEVICE=0;/IS_SLOT_DEVICE=auto;/g' AnyKernel3/anykernel.sh
```

### 5. fate-think release 死链
**原因**：fate-think/LXC-DOCKER-KernelSU_Action 的 releases 已删除，runcpatch.sh 和 clangfix3.sh 下载 404。
**修复**：改用本仓库 android-lxc-docker 的 `scripts-legacy/` 下备份（runcpatch.sh、clangfix2.sh）。

---

## 六、KernelSU 说明

### 当前方案（5.4 GKI）

内核源码已内置 KernelSU（`drivers/staging/kernelsu/`，来自 backslashxx/KernelSU v3.2.5+），Kconfig 中 `CONFIG_KSU` 默认 y，无需工作流 setup.sh 注入。刷入后装对应版本管理器即可。

### [4.14遗留] 旧版方案

`[4.14遗留]` 4.14 非 GKI 时代通过 `tiann/KernelSU` 的 `setup.sh` 注入 v0.9.5（最后支持非 GKI 的官方版本）。此方案已弃用，仅存档。

---

## 七、致谢

- [AnyKernel3](https://github.com/osm0sis/AnyKernel3)
- [AOSP](https://android.googlesource.com)
- [KernelSU](https://github.com/tiann/KernelSU)
- [HeliumStudio-Dev](https://github.com/HeliumStudio-Dev)（5.4 GKI 内核源码）
- [wu17481748](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)
- [ego-taboo](https://github.com/ego-taboo)
- [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS)
