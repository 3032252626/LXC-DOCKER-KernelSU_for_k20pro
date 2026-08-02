# LXC-DOCKER-KernelSU_Action

基于 GitHub Actions 的安卓内核自动编译工具，集成 KernelSU 与 LXC/Docker 支持。fork 自 [wu17481748/LXC-DOCKER-KernelSU_Action](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)。

### KernelSU 非 GKI 适配

KernelSU 官方自 v1.0 起放弃非 GKI 内核支持。本仓库改用社区维护的 [rsuntk/KernelSU](https://github.com/rsuntk/KernelSU) fork（通过 tiann 脚本 v0.9.5 集成），该 fork 持续 backport 至 4.4~6.18 内核。

---

## 一、项目介绍

本仓库提供 GitHub Actions 工作流，一键编译支持 LXC/Docker 容器 + KernelSU 的安卓内核。

### 内核版本

`4.14`

### 补丁与脚本

| 文件 | 来源 | 用途 |
|------|------|------|
| `LXC-DOCKER-OPEN-CONFIG.sh` | [android-lxc-docker](https://github.com/3032252626/android-lxc-docker) | LXC/Docker 内核配置注入 |
| `xt_qtaguid.patch` | 同上 | qtaguid 网络模块补丁 |
| Droidspaces 补丁 01/02 | [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) | Non-GKI xt_qtaguid panic 修复 + cgroup 前缀处理 |
| `setup.sh` (v0.9.5) | [tiann/KernelSU](https://github.com/tiann/KernelSU) | KernelSU 驱动集成 |

---

## 二、快速开始

1. **Fork 本仓库**
2. **编辑配置** — `config.env` 按需修改后 Commit
3. **选择工作流** — Actions → 选择对应工作流
4. **触发编译** — Run workflow
5. **下载产物** — 从 Artifacts 下载 AnyKernel3 刷入包

---

## 三、config.env 配置说明

| 变量 | 说明 | 示例 |
|------|------|------|
| `KERNEL_SOURCE` | 内核源码仓库 | `https://github.com/xxx/kernel_xxx` |
| `KERNEL_SOURCE_BRANCH` | 内核源码分支 | `oss-base` |
| `KERNEL_CONFIG` | defconfig 文件名 | `raphael_defconfig` |
| `KERNEL_ZIP_NAME` | 产物命名 | `raphael_lxc-docker_kernel` |
| `LLVM_CONFIG` | 是否启用 LLVM=1 | `y` / `n` |
| `ENABLE_KVM` | 是否开启 KVM | `true` / `false` |
| `ENABLE_LXC_DOCKER` | 是否开启 LXC/Docker | `true` / `false` |
| `ENABLE_KERNELSU` | 是否集成 KernelSU | `true` / `false` |
| `KERNELSU_TAG` | KernelSU 分支标签 | `v0.9.5` |
| `ENABLE_PATH_UMOUNT` | 是否启用 path_umount | `true` / `false` |

---

## 四、工作流选型

### 常规编译

| 工作流 | 编译器 | 方案 |
|--------|--------|------|
| `build-AB-clang14.yml` | Google clang 14 | 方案1 - kprobe |
| `build-AB-clang14-plan2.yml` | Google clang 14 | 方案2 - 手动源码补丁 |

### Droidspaces 编译（Non-GKI）

Droidspaces 工作流在常规编译基础上额外注入 Non-GKI 必需的内核配置项（SYSVIPC、DEVTMPFS、cgroup/netfilter 等）并应用 Droidspaces-OSS 官方补丁。

| 工作流 | 编译器 | 方案 |
|--------|--------|------|
| `build-droidspaces-clang14.yml` | Google clang 14 | 方案1 - kprobe |
| `build-droidspaces-clang14-plan2.yml` | Google clang 14 | 方案2 - 手动源码补丁 |

> 方案1（kprobe）与方案2（手动源码补丁）二选一即可，config.env 通用。

---

## 五、常见编译问题

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

---

## 六、KernelSU 双方案说明

| 方案 | 原理 | 优缺点 |
|------|------|--------|
| 方案1 - kprobe | 依赖 `CONFIG_KPROBES`，KernelSU 自动注入 hook | 简洁，但需要内核开启 kprobe |
| 方案2 - 手动源码补丁 | 直接修改 `fs/exec.c`/`open.c`/`read_write.c`/`stat.c` 注入 KSU 回调 | 不依赖 kprobe，兼容性更好 |

---

## 七、致谢

- [AnyKernel3](https://github.com/osm0sis/AnyKernel3)
- [AOSP](https://android.googlesource.com)
- [KernelSU](https://github.com/tiann/KernelSU)（非 GKI 兼容由 [rsuntk/KernelSU](https://github.com/rsuntk/KernelSU) 提供）
- [wu17481748](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)
- [ego-taboo](https://github.com/ego-taboo)
- [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS)
- [xiaoleGun](https://github.com/xiaoleGun/KernelSU_Action)
- [xiaoxindada](https://github.com/xiaoxindada)
