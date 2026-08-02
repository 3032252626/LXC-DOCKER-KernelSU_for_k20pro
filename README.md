[中文](README.md)
[English](README_EN.md)
# LXC-DOCKER-KernelSU_Action

基于 GitHub Actions 的安卓内核自动编译工具，集成 KernelSU 与 LXC/Docker 支持。

fork 自 [wu17481748/LXC-DOCKER-KernelSU_Action](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)。

---

## KernelSU 集成方案

KernelSU 官方自 v1.0 起放弃非 GKI 内核支持（最后支持版本 v0.9.5）。本仓库提供两种集成方案，KSU 内核模块均使用 tiann/KernelSU v0.9.5。

### 方案对比

| | 方案1：kprobe（默认） | 方案2：手动源码补丁 |
|---|---|---|
| **原理** | 通过 kprobe 运行时注册探针 hook 内核函数 | 编译前向内核源码插入 `#ifdef CONFIG_KSU` 钩子 |
| **开机速度** | 偏慢（kprobe 初始化开销） | 快 |
| **维护成本** | 低 | 需维护 4 个内核文件的补丁 |
| **工作流** | `build-AB-clang14.yml` | `build-AB-clang14-plan2.yml` |
| **配置要求** | `CONFIG_KPROBES=y` | `CONFIG_KSU=y`，关闭 `CONFIG_KPROBES` |

> 红米 K20 Pro (raphael, 4.14 内核) 推荐方案1。方案2 开机更快但需随内核源码更新维护补丁。

---

## 快速开始

1. **Fork 本仓库**
2. **编辑** `config.env` 按需修改后 Commit
3. **选择工作流** → Actions → 触发编译
4. **下载产物** 刷入

---

## config.env 配置

| 变量 | 说明 | 示例 |
|------|------|------|
| `KERNEL_SOURCE` | 内核源码仓库 | `https://github.com/xxx/kernel_xxx` |
| `KERNEL_SOURCE_BRANCH` | 源码分支 | `oss-base` |
| `KERNEL_CONFIG` | defconfig 文件名 | `raphael_defconfig` |
| `KERNEL_ZIP_NAME` | 产物名 | `raphael_lxc-kernel` |
| `ENABLE_KVM` | 开启 KVM | `true` / `false` |
| `ENABLE_LXC_DOCKER` | 开启 LXC/Docker | `true` / `false` |
| `ENABLE_KERNELSU` | 集成 KernelSU | `true` / `false` |
| `KERNELSU_TAG` | KSU 分支 | `main` |
| `ENABLE_PATH_UMOUNT` | path_umount 回移植 | `true` |
| `KERNEL_IMAGE_NAME` | 镜像类型 | `Image.gz` / `Image.gz-dtb` |
| `LLVM_CONFIG` | LLVM=1 | `y` / `n` |

---

## 工作流选型

### 机型分类
- **A/B 分区（高端机）**：红米 K20 Pro / K30 Pro、一加 8T、小米 10 等 — 选文件名含 `AB` 的工作流
- **非 A/B 分区（低端机）**：小米 6、红米 5 Plus 等 — 选不含 `AB` 的工作流

### raphael 主力工作流

| 文件 | 方案 | 说明 |
|------|------|------|
| `build-AB-clang14.yml` | **方案1 kprobe（推荐）** | 默认 |
| `build-AB-clang14-plan2.yml` | 方案2 手动源码补丁 | 开机更快，维护成本高 |

### 其他工作流

| 文件 | 编译器 | 机型 |
|------|--------|------|
| `build-clang12.yml` | clang 12 | 低端机 |
| `build-clang14.yml` | clang 14 | 低端机 |
| `build-AB-clang12.yml` | clang 12 | 高端机 |
| `build-AB-zyc-clang18.yml` | zyc clang 18 | 高端机 |
| `build-zyc-clang18.yml` | zyc clang 18 | 低端机 |
| `build-Mandi-Sa-clang18.yml` | Mandi-Sa clang 18 | 低端机 |

---

## 常见编译问题

### DTC 链接报 yaml 未定义
```bash
sed -i 's/HOSTLDLIBS_dtc/HOSTLOADLIBES_dtc/g' scripts/dtc/Makefile
```

### struct timespec 与 timespec64 不兼容（clang 14）
```bash
sed -i 's/struct timespec now = current_time/struct timespec64 now = current_time/' fs/btrfs/inode.c fs/btrfs/file.c
```

### arch/arm64/mm/hugetlbpage.c 编译报错
```bash
sed -i 's/ptep = huge_pmd_share/pte = huge_pmd_share/' arch/arm64/mm/hugetlbpage.c
```

### TWRP 刷入报 "Unable to determine boot partition"
确保工作流 sed 匹配大写 `BLOCK=`（非小写 `block=`）：
```bash
sed -i 's!BLOCK=/dev/block/platform/omap/omap_hsmmc.0/by-name/boot;!BLOCK=/dev/block/bootdevice/by-name/boot;!g' AnyKernel3/anykernel.sh
```

### k30pro / 一加9R 不生成 Image.gz
在 defconfig 追加：
```ini
CONFIG_BUILD_ARM64_KERNEL_COMPRESSION_GZIP=y
CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE=y
CONFIG_BUILD_ARM64_DT_OVERLAY=y
```

---

## 修复记录

### 2026-08-02 — KernelSU 双方案支持

- 新增方案2（手动源码补丁，开机更快），保留方案1（kprobe）为默认
- 两套工作流独立命名标注，config.env 通用，无需切换配置

### 2026-08-01 — raphael (K20 Pro) 初始适配

使用 `build-AB-clang14` + `kernel_xiaomi_raphael` (oss-base)，编译到实机刷入全流程通过。

| 文件 | 问题 | 修复 |
|------|------|------|
| `scripts/dtc/Makefile` | `HOSTLDLIBS_dtc` 不兼容 | sed → `HOSTLOADLIBES_dtc` |
| `arch/arm64/mm/hugetlbpage.c` | `ptep` 不存在 | sed → `pte` |
| `fs/btrfs/inode.c` `file.c` | `struct timespec` 废弃 | sed → `timespec64` |
| AnyKernel3 | 小写 `block=` 匹配失败 | 改为大写 `BLOCK=` |

---

## 致谢

- [AnyKernel3](https://github.com/osm0sis/AnyKernel3)
- [KernelSU](https://github.com/tiann/KernelSU)
- [rsuntk/KernelSU](https://github.com/rsuntk/KernelSU)（非 GKI backport）
- [xiaoleGun](https://github.com/xiaoleGun/KernelSU_Action)
- [wu17481748](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)
- [xiaoxindada](https://github.com/xiaoxindada)
- [zyc clang](https://github.com/ZyCromerZ/Clang)
- [Mandi-Sa](https://github.com/Mandi-Sa/clang)
