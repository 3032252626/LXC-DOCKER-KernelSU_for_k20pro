[中文](README.md)
[English](README_EN.md)
# LXC-DOCKER-KernelSU_Action

基于 GitHub Actions 的安卓内核自动编译工具，集成 KernelSU 与 LXC/Docker 支持。

fork 自 [wu17481748/LXC-DOCKER-KernelSU_Action](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)。

> **声明**：本仓库工作流及补丁体系均源自上游社区，未进行自主开发维护。编译适配、问题排查与修复均由 AI 辅助完成。

---

## 一、项目介绍

本仓库提供一系列 GitHub Actions 工作流，可一键编译支持 LXC/Docker 容器的安卓内核，同时集成 KernelSU 提权方案。

### 支持的内核版本
`4.9` | `4.14` | `4.19` | `5.4`

### 补丁体系
补丁取自上游社区仓库，本仓库仅做引用整合，通过 AI 排查适配：

| 文件 | 来源 | 用途 |
|------|------|------|
| `LXC-DOCKER-OPEN-CONFIG.sh` | [android-lxc-docker](https://github.com/3032252626/android-lxc-docker)（fork 自 wu17481748） | 注入 LXC/Docker 内核配置 |
| `xt_qtaguid.patch` | 同上 | qtaguid 网络模块补丁 |

> `cgroup.patch` 已移除 — 较新内核源码已内置 cgroup 支持，重复打补丁会导致编译冲突（由 AI 分析后决策）。

---

## 二、快速开始

所有流程沿用上游设计，仅通过 AI 完成机型适配与问题修复。

1. **Fork 本仓库**
2. **编辑配置** — 打开 `config.env`，按注释修改变量后 Commit
3. **选择工作流** — 上方菜单 Actions → All workflows，根据机型选择
4. **触发编译** — Run workflow → 确认
5. **下载产物** — 编译完成后从 Artifacts 下载刷入

---

## 三、config.env 配置说明

沿用上游变量体系，未做自定义扩展。

| 变量 | 说明 | 示例 |
|------|------|------|
| `KERNEL_SOURCE` | 内核源码仓库地址 | `https://github.com/xxx/kernel_xxx` |
| `KERNEL_SOURCE_BRANCH` | 内核源码分支 | `oss-base` |
| `KERNEL_CONFIG` | defconfig 文件名 | `raphael_defconfig` |
| `KERNEL_ZIP_NAME` | 产物命名 | `raphael_lxc-docker_kernel` |
| `ENABLE_KVM` | 是否开启 KVM | `true` / `false` |
| `ENABLE_LXC_DOCKER` | 是否开启 LXC/Docker | `true` / `false` |
| `KERNEL_IMAGE_NAME` | 打包镜像类型 | `Image.gz` / `Image.gz-dtb` / `Image` |
| `LLVM_CONFIG` | 是否启用 LLVM=1 | `y` / `n` |
| `SWITCH_PYTHON` | 是否切换到 Python 2 | `true` / `false` |
| `NEED_DTBO` | 是否需要 DTBO | `true` / `false` |
| `ENABLE_KERNELSU` | 是否集成 KernelSU | `true` / `false` |
| `KERNELSU_TAG` | KernelSU 分支 | `main` |

---

## 四、工作流选型

工作流均来自上游或 ego-taboo，本仓库仅做归档整合，适配修改由 AI 完成。

### 机型分类
- **高端机（A/B 分区）**：一加 8T、红米 K20 Pro / K30 Pro、小米 10 等 — 选用文件名含 `AB` 的工作流
- **低端机（非 A/B 分区）**：小米 6、红米 5 Plus、红米 Note4X 等 — 选用不含 `AB` 的工作流

### 主力工作流

| 工作流文件 | 编译器 | 适用机型 | 来源 |
|------------|--------|----------|------|
| `build-clang12.yml` | Google clang 12 | 低端机 | 上游 |
| `build-clang14.yml` | Google clang 14 | 低端机 | 上游 |
| `build-AB-clang12.yml` | Google clang 12 | 高端机 | 上游 |
| `build-AB-clang14.yml` | Google clang 14 | 高端机 | 上游（已 AI 适配 raphael） |
| `build-zyc-clang18.yml` | zyc clang 18 | 低端机 | 上游 |
| `build-AB-zyc-clang18.yml` | zyc clang 18 | 高端机 | 上游 |
| `build-Mandi-Sa-clang18.yml` | Mandi-Sa clang 18 | 低端机 | 上游 |

编译失败时优先降级到 clang 14 或 clang 12 重试，问题排查由 AI 辅助。

### 旧版工作流（归档）

来自 ego-taboo，脚本已备份至 [android-lxc-docker/scripts-legacy/](https://github.com/3032252626/android-lxc-docker/tree/main/scripts-legacy)，仅做存档，不推荐新项目使用：

| 工作流文件 | 编译器 | 适用机型 | 说明 |
|------------|--------|----------|------|
| `build-clang12-simplified-v5-legacy` | Google clang 12 | 低端机 | 无 KernelSU，极简配置 |
| `build-zyc-clang23-simplified-universal-legacy` | zyc clang 23 | 低端机 | clang23 + clangfix2 修复 |
| `build-clang12-simplified-vince-A16-v6-legacy` | Google clang 12 | 红米5 Plus (vince) | vince 专用，含额外驱动仓库 |

---

## 五、常见编译问题

以下问题及修复方案均来自上游社区经验或 AI 分析，非自主开发。

### k30pro / 一加9R los 内核不生成 Image.gz
在 defconfig 末尾追加：（来源：上游社区）
```ini
CONFIG_BUILD_ARM64_KERNEL_COMPRESSION_GZIP=y
CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE=y
CONFIG_BUILD_ARM64_DT_OVERLAY=y
```

### .py 文件报 print 语法错误
`config.env` 中设置 `SWITCH_PYTHON=true`。（来源：上游已知问题）

### DTC 链接报 yaml 未定义
在编译步骤前执行：（来源：AI 分析 raphael 编译日志）
```bash
sed -i 's/HOSTLDLIBS_dtc/HOSTLOADLIBES_dtc/g' scripts/dtc/Makefile
```

### struct timespec 与 timespec64 不兼容
在编译步骤前执行：（来源：AI 分析 raphael 编译日志）
```bash
sed -i 's/struct timespec now = current_time/struct timespec64 now = current_time/' fs/btrfs/*.c
```

---

## 六、修复记录

以下适配由 AI 辅助分析编译日志完成，非手动逆向。

### 2026-08-01 — raphael (红米 K20 Pro) 适配

使用 `build-AB-clang14` + `kernel_xiaomi_raphael` (oss-base) 编译通过。

| 文件 | 问题 | 修复方式 |
|------|------|----------|
| `scripts/dtc/Makefile` | `HOSTLDLIBS_dtc` 变量名不兼容 | sed 改为 `HOSTLOADLIBES_dtc` |
| `arch/arm64/mm/hugetlbpage.c` | `ptep` 成员不存在 | sed 改为 `pte` |
| `fs/btrfs/inode.c` | `struct timespec` 已废弃 | sed 改为 `struct timespec64` |
| `fs/btrfs/file.c` | 同上 | sed 改为 `struct timespec64` |

编译产物：`raphael_zundamon-fox_lxc-docker_kernel`（约 21.8 MB）。

> ⚠️ **免责声明**：此产物仅验证编译通过，未在实机上测试开机及功能。LXC/Docker、KernelSU 等模块的实际运行效果未经确认，刷入前请自行备份，风险自负。

---

## 七、致谢

- [AnyKernel3](https://github.com/osm0sis/AnyKernel3)
- [AOSP](https://android.googlesource.com)
- [KernelSU](https://github.com/tiann/KernelSU)
- [xiaoxindada](https://github.com/xiaoxindada)
- [xiaoleGun](https://github.com/xiaoleGun/KernelSU_Action)
- [wu17481748](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)
- [qiuqiu](https://github.com/lateautumn233)
- [zyc clang](https://github.com/ZyCromerZ/Clang)
- [Mandi-Sa](https://github.com/Mandi-Sa/clang)
- [ego-taboo](https://github.com/ego-taboo)
