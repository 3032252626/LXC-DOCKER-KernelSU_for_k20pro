# LXC-DOCKER-KernelSU_Action

基于 GitHub Actions 的 Android 内核自动编译工作流，为 **Redmi K20 Pro（raphael，骁龙 855，4.14 非 GKI 内核）** 一键编译带 LXC/Docker 容器支持 + KernelSU root 的内核，产物为 AnyKernel3 刷入包。

fork 自 [wu17481748/LXC-DOCKER-KernelSU_Action](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)。

## 实测环境

| 项目 | 说明 |
|---|---|
| 设备 | Redmi K20 Pro 尊享版（raphael） |
| 内核 | 4.14.357，非 GKI |
| 容器 | Droidspaces（Debian 13 + 青龙 + 1Panel） |
| Root | KernelSU v0.9.5（最后支持非 GKI 的官方版本） |

## 仓库关系

```
本仓库（编译工作流）
  │  config.env 指向 ↓
  ▼
kernel_xiaomi_raphael        ←  内核源码（已 force push 到上游 QCerberusQ 干净基线）
android-lxc-docker           ←  LXC/Docker 配置注入脚本与补丁
```

> **重要**：内核源码仓库保持上游干净状态，**不包含任何本地修改**。所有 LXC/Docker/DroidSpaces 所需的内核配置和源码补丁，都在编译时由本仓库的 workflow 自动注入。fork 上游即可重新编译，无需手动 patch 内核树。

## 快速开始

1. Fork 本仓库
2. 编辑 `config.env`（一般只需改 `KERNEL_ZIP_NAME`）
3. Actions → **Droidspaces Non-GKI 谷歌clang14 [方案1-kprobe]** → Run workflow
4. 从 Artifacts 下载 AnyKernel3 zip，Recovery 刷入

## config.env

| 变量 | 说明 | 当前值 |
|---|---|---|
| `KERNEL_SOURCE` | 内核源码仓库 | `https://github.com/3032252626/kernel_xiaomi_raphael` |
| `KERNEL_SOURCE_BRANCH` | 源码分支 | `oss-base` |
| `KERNEL_CONFIG` | defconfig | `raphael_defconfig` |
| `KERNEL_ZIP_NAME` | 产物 zip 名 | `raphael_Zundamon-v4.1-LXC-KernelSU-tiann` |
| `ENABLE_KVM` | KVM 支持 | `false` |
| `ENABLE_LXC_DOCKER` | LXC/Docker 支持 | `true` |
| `ENABLE_KERNELSU` | KernelSU | `true` |
| `ENABLE_PATH_UMOUNT` | path_umount | `true` |
| `LLVM_CONFIG` | LLVM=1 | `n` |
| `NEED_DTBO` | 打包 dtbo | `false` |

## 工作流选择

只用这个：**`build-droidspaces-clang14.yml`**（Google clang 14 + kprobe 方案）。其余三个 `build-AB-*` / `plan2` 是历史遗留备用，不推荐。

## 编译时做了什么

1. 拉取上游干净内核源码
2. 运行 `LXC-DOCKER-OPEN-CONFIG.sh -w` 注入 ~130 项 Namespace/Cgroup/Netfilter 配置
3. 手动追加 DroidSpaces Non-GKI 必需配置（SYSVIPC、DEVTMPFS、OVERLAY_FS、nftables 等共 50 项）
4. 应用 `xt_qtaguid.patch` + DroidSpaces-OSS 官方补丁（修 qtaguid panic、cgroup 前缀）
5. 注入 KernelSU v0.9.5（kprobe 方案）+ `path_umount()` 函数
6. clang 14 编译，打包 `Image.gz-dtb` 进 AnyKernel3

## 常见问题

**容器起不来 / DroidSpaces 启动失败**：确认内核 `CONFIG_SYSVIPC=y` 和 `CONFIG_DEVTMPFS=y`（workflow 已自动加，手动编译时容易漏）。

**KernelSU 管理器报"只支持 GKI"**：本仓库注入的是 v0.9.5（驱动版本 11872），必须配 v0.9.5 管理器；不要用官方 v3.x 管理器。

**AnyKernel3 报 "Unable to determine boot partition"**：workflow 里已用 sed 把 `BLOCK=` 路径改为 `/dev/block/bootdevice/by-name/boot`，自己改 AnyKernel3 时注意。

## 致谢

- [AnyKernel3](https://github.com/osm0sis/AnyKernel3)
- [KernelSU](https://github.com/tiann/KernelSU)（非 GKI 兼容参考 [rsuntk/KernelSU](https://github.com/rsuntk/KernelSU)）
- [DroidSpaces-OSS](https://github.com/ravindu644/Droidspaces-OSS)
- [wu17481748](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)
- [QCerberusQ](https://github.com/QCerberusQ/kernel_xiaomi_raphael)（上游内核源码）
