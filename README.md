# LXC-DOCKER-KernelSU_Action

基于 GitHub Actions 的安卓内核自动编译工具，集成 KernelSU 与 LXC/Docker 支持。fork 自 [wu17481748/LXC-DOCKER-KernelSU_Action](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)。

> **声明**：本仓库工作流及补丁体系均源自上游社区，未进行自主开发维护。编译适配、问题排查与修复均由 AI 辅助完成。

> **当前状态（2026-09-21 更新）**：已从 4.14 非 GKI 内核迁移到 **5.4.302 内核**（fork 自 HeliumStudio-Dev/kernel_xiaomi_raphael-5.4），5.4 内核已内置 KernelSU，无需 setup.sh 注入。仓库工作流已精简为 **2 个**：`build-zundamon-5.4-lxc.yml`（当前主力）与 `build-droidspaces-clang14.yml`（4.14 遗留，仅存档）。此前并列的 `build-droidspaces-clang18.yml`、`build-AB-zyc.yml` 已删除，`build-AB-Mandi-Sa.yml` 因上游 codeberg 仓库失效一并移除。以下文档中标注 `[4.14遗留]` 的内容仅供历史参考，不适用于当前 5.4 编译。

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

`5.4.302`（`zundamon-miui-5.4` 分支）

### 补丁与脚本

| 文件 | 来源 | 用途 | 适用 |
|------|------|------|------|
| Droidspaces 补丁 `01.fix_kernel_panic_in_xt_qtaguid.patch` | [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) | xt_qtaguid panic 修复（non-GKI） | 5.4 主力 |
| Droidspaces 补丁 `02.fix_restore cgroup file prefix handling.patch` | 同上 | cgroup 文件前缀处理修复 | 5.4 主力 |
| `LXC-DOCKER-OPEN-CONFIG.sh` | [android-lxc-docker](https://github.com/3032252626/android-lxc-docker) | LXC/Docker 内核配置注入 | `[4.14遗留]` |
| `xt_qtaguid.patch` | 同上 | qtaguid 补丁（与官方 01 同文件同目的，5.4 已不再重复应用） | `[4.14遗留]` |
| `runcpatch.sh` / `clangfix2.sh` | 同上 `scripts-legacy/` | runc cgroup 兼容、clang Makefile 修复 | `[4.14遗留]` |

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
| `KERNEL_ZIP_NAME` | 产物 zip 命名 | `raphael_Zundamon-5.4-LXC-KSU` |
| `KERNEL_IMAGE_NAME` | 打包的内核镜像 | `Image.gz`（GKI 不拼 DTB，无 Image.gz-dtb） |
| `LLVM_CONFIG` | 是否启用 LLVM=1 / LLVM_IAS=1 | `y`（亦可由工作流 input `llvm_config` 覆盖） |
| `ENABLE_KVM` | 是否开启 KVM | `false` |
| `ENABLE_LXC_DOCKER` | 是否开启 LXC/Docker | `true` |
| `ENABLE_KERNELSU` | 是否通过 setup.sh 注入 KSU | `false`（5.4 内核已内置 KSU，无需注入） |
| `KERNELSU_TAG` | 保留备用 | `v0.9.5` |
| `ENABLE_PATH_UMOUNT` | 是否启用 path_umount | `false` |
| `SWITCH_PYTHON` | 是否切换 python2 | `false` |
| `NEED_DTBO` | 是否构建 dtb/dtbo.img 并打进卡刷包 | `true` |

---

## 四、工作流清单

### 当前在用

| 工作流 | 名称 | 编译器 | 说明 |
|--------|------|--------|------|
| `build-zundamon-5.4-lxc.yml` | Zundamon-5.4 LXC/Docker [raphael] | AOSP clang（`android13-release` / clang-r450784d），失败回退 ZyCromerZ Clang 18.0.0-20230903 | **当前主力**，5.4 专用。容器配置注入（5.4 校准清单）+ Droidspaces non-GKI 补丁 + dtb/dtbo 构建打包 + 容器配置自检 |
| `build-droidspaces-clang14.yml` | Droidspaces Non-GKI 谷歌clang14 [方案1-kprobe] | AOSP clang（`android13-release` / clang-r450784d） | `[4.14遗留]` 旧 4.14 主工作流，仅存档，不适用于 5.4 |

### 已移除

| 工作流 | 移除原因 |
|--------|----------|
| `build-droidspaces-clang18.yml` | 2026-09-21 删除（功能已被 `build-zundamon-5.4-lxc.yml` 覆盖） |
| `build-AB-zyc.yml` | 2026-09-21 删除 |
| `build-AB-Mandi-Sa.yml` | 上游 codeberg 仓库已失效 |

### 主力工作流可调参数（workflow_dispatch inputs）

| 参数 | 取值 | 默认 | 说明 |
|------|------|------|------|
| `llvm_config` | y / n | `y` | LLVM=1 LLVM_IAS=1（CFI_CLANG 需要；编译报错时可改 n） |
| `enable_lxc` | true / false | `true` | true=容器版（注入 LXC/Docker 配置与 Droidspaces 补丁）；false=基线版（仅设备支持） |
| `build_dtbo` | true / false | `true` | 构建 dtb/dtbo.img 并打进卡刷包 |

产物命名：`{KERNEL_ZIP_NAME}-lxc`（或 `-base`）卡刷包 + `{KERNEL_ZIP_NAME}-config` 配置校验包。

---

## 五、5.4 工作流版本演进

### v3（相对 v2，5 处改动）

1. **容器配置注入**：改用「5.4 校准清单 + 末尾追加覆盖」方式，剔除 28 项该树不存在的符号与畸形项 `CONFIG_!SCHED_WALT`
2. **补丁注入**：去掉与我方仓 `xt_qtaguid.patch` 重复的应用（与官方 01 同文件同目的），改为 dry-run 幂等应用
3. **dtb/dtbo 构建**：修正手工兜底（`dtbo.img` 只放 overlay，不再塞 base dtb），并加硬断言
4. **打包**：把 `sm8150-v2.dtb`（命名为 dtb）与 `dtbo.img` 一并放进 AnyKernel3，实现三件套同源一次卡刷
5. **新增「容器配置自检」**：对 `out/.config` 断言关键项已生效，并对调度类项断言保持关闭

### v4（相对 v3，1 处关键修正，真机刷入实测闭环）

6. **打包**：raphael 原厂 boot 为 header v0，dtb 是 append 在内核段尾部的；AnyKernel3 的 dtb 替换只认 v2 独立 dtb 段，v0 下 `split_img` 无 `boot.img-dtb`，替换被静默跳过 —— 实测 v3 包刷入后 boot 内仍是原厂 4.14 dtb（446802B），与包内 5.4 自编译 dtbo 不同源，ABL 合并 overlay 失败直接回落 fastboot。v4 改为：把 `sm8150-v2.dtb` 直接 append 进内核镜像文件（不再单列 dtb 文件），随 kernel 段一起写入 boot，并新增「内核段尾部 dtb 与自编译 dtb 逐字节一致」硬断言，不一致直接禁止出包。（该修复产物已真机验证可开机）

---

## 六、编译适配记录

以下为从 4.14 迁移到 5.4 过程中遇到的编译错误及修复，记录备查：

### 1. `netprio_cgroup.h: no member named 'id' in 'struct cgroup'`
**原因**：5.4 的 `struct cgroup` 已无 `id` 成员，而容器配置注入又需要 `CONFIG_CGROUP_NET_PRIO=y`。
**修复**：改为源码层修复 —— 全树 `css->cgroup->id` → `css->id` 统一替换（含 `include/net/netprio_cgroup.h`、`net/core/netprio_cgroup.c`），并加残留检查。

### 2. `htc_recv.c: snprintf will always be truncated [-Werror,-Wfortify-source]`
**原因**：clang 18 对 WiFi 驱动的 fortify-source 检查过严，旧代码 snprintf 缓冲区太小。
**修复**：编译命令加 `KCFLAGS="-Wno-error=fortify-source"`（仅在回退到 ZyC clang 18 时涉及）。

### 3. `ld.lld: error: undefined symbol: probe_user_write`
**原因**：旧版 fs API 未适配 5.4，btrfs 等代码引用了 `probe_user_write`。
**修复**：全树 `probe_user_write(/probe_user_read(` → `copy_to_user_nofault(/from_user_nofault(` 替换；btrfs 的 `current_time` 同步改为 `timespec64`。（早期曾以禁用 BTRFS 规避）

### 4. `HOSTLD scripts/dtc/dtc` 链接失败
**原因**：5.4 的 dtc 需链接 libyaml，`pkg-config` 缺失导致链接失败。
**修复**：在 `scripts/dtc/Makefile` 强制写入 `HOSTLDLIBS_dtc := -lyaml`。

### 5. dtb/dtbo 构建条件宏失配
**原因**：`arch/arm64/boot/dts/qcom/Makefile` 使用 `CONFIG_MACH_XIAOMI_SM8150`，与 5.4 树不符。
**修复**：替换为 `CONFIG_ARCH_SM8150`，并确保 `dtb-y += sm8150-v2.dtb`。

### 6. AnyKernel3 刷入报 "Unable to determine boot partition"
**原因**：上游 AnyKernel3 的 anykernel.sh 用大写 `BLOCK=` 和 `IS_SLOT_DEVICE=`，sed 必须匹配大写。
**修复**：
```bash
sed -i 's!BLOCK=/dev/block/platform/omap/omap_hsmmc.0/by-name/boot;!BLOCK=auto;!g' AnyKernel3/anykernel.sh
sed -i 's/IS_SLOT_DEVICE=0;/IS_SLOT_DEVICE=auto;/g' AnyKernel3/anykernel.sh
```

### 7. fate-think release 死链
**原因**：fate-think/LXC-DOCKER-KernelSU_Action 的 releases 已删除，runcpatch.sh 和 clangfix3.sh 下载 404。
**修复**：改用本仓库 android-lxc-docker 的 `scripts-legacy/` 下备份（runcpatch.sh、clangfix2.sh）。

---

## 七、KernelSU 说明

### 当前方案（5.4）

内核源码已内置 KernelSU（`drivers/staging/kernelsu/`，来自 backslashxx/KernelSU v3.2.5+），Kconfig 中 `CONFIG_KSU` 默认 y，无需工作流 setup.sh 注入。刷入后装对应版本管理器即可。

### `[4.14遗留]` 旧版方案

4.14 非 GKI 时代通过 `tiann/KernelSU` 的 `setup.sh` 注入 v0.9.5（最后支持非 GKI 的官方版本）。此方案已弃用，仅存档。

---

## 八、致谢

- [AnyKernel3](https://github.com/osm0sis/AnyKernel3)
- [AOSP](https://android.googlesource.com)
- [KernelSU](https://github.com/tiann/KernelSU)
- [HeliumStudio-Dev](https://github.com/HeliumStudio-Dev)（5.4 内核源码）
- [wu17481748](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)
- [ego-taboo](https://github.com/ego-taboo)
- [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS)
