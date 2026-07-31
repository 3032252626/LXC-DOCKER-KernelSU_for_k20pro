[中文](README.md)
[English](README_EN.md)
# LXC-DOCKER-KernelSU_Action

## 支持的内核版本
4.9&emsp;&emsp;4.14&emsp;&emsp;4.19&emsp;&emsp;5.4

## 编译器版本
| 编译器 | 适用机型 | 说明 |
|--------|----------|------|
| Google clang 12 | 低端机 / 高端机 | 最稳定，兼容性最好 |
| Google clang 14 | 低端机 / 高端机 | 较新内核推荐 |
| zyc clang 18 | 低端机 / 高端机 | 自编译 clang |
| Mandi-Sa clang 18 | 低端机 | 带 BOLT 等优化 |
| zyc clang 23（旧版） | 低端机 | 简化配置，见下方说明 |

## 步骤
1. fork 本仓库，打开 `config.env` 编辑变量，Commit changes
2. 上方菜单选择 Actions → All workflows，按需选择工作流
3. 点击 Run workflow 触发，等待完成
4. 从 Artifacts 下载编译好的内核

## 提示
- 如果编译不过，优先尝试 clang 14 或 clang 12
- 高端机指 A/B 分区机型（一加8T、红米 K20 Pro/K30 Pro、小米10 等），工作流文件名含 `AB` 字样
- 低端机指非 A/B 分区机型（小米6、红米5 Plus、红米 Note4X 等）
- `config.env` 文件内有变量说明

## LXC-DOCKER 补丁源
本仓库使用自维护的补丁仓库 [android-lxc-docker](https://github.com/3032252626/android-lxc-docker)，包含：

| 文件 | 用途 |
|------|------|
| `LXC-DOCKER-OPEN-CONFIG.sh` | LXC/Docker 内核配置脚本 |
| `xt_qtaguid.patch` | qtaguid 网络模块补丁 |
| `scripts-legacy/` | ego-taboo 旧版脚本备份（简化配置用） |

> `cgroup.patch` 已移除，较新内核源码已内置 cgroup 支持。

## 旧版工作流

以下 3 个工作流来自 ego-taboo，采用简化 LXC 配置方案（去除约 80 项冗余内核配置项），已归档保留供参考：

| 工作流 | 编译器 | 适用场景 | 特点 |
|--------|--------|----------|------|
| `build-clang12-simplified-v5-legacy` | Google clang 12 | 通用低端机 | 无 KernelSU，极简配置 |
| `build-zyc-clang23-simplified-universal-legacy` | zyc clang 23 | 通用低端机 | clang23 + clangfix2 修复 |
| `build-clang12-simplified-vince-A16-v6-legacy` | Google clang 12 | 红米5 Plus (vince) A16 | vince 专用，含额外驱动仓库 |

> 旧版工作流依赖 `android-lxc-docker/scripts-legacy/` 下的脚本，与当前主力工作流的补丁体系不同。新项目建议使用主力工作流。

## 修复记录

### 2026-08-01 · raphael (红米 K20 Pro) 内核适配

以下修复针对 `kernel_xiaomi_raphael` 源码，使用 `build-AB-clang14` 工作流。

| 文件 | 问题 | 修复 |
|------|------|------|
| `scripts/dtc/Makefile` | `HOSTLDLIBS_dtc` 在新版 Make 中不生效 | 改为 `HOSTLOADLIBES_dtc` |
| `arch/arm64/mm/hugetlbpage.c` | `ptep` 成员不存在 | 改为 `pte` |
| `fs/btrfs/inode.c` | `struct timespec` 已废弃 | 改为 `struct timespec64` |
| `fs/btrfs/file.c` | 同上 | 改为 `struct timespec64` |

> 编译产物：`raphael_zundamon-fox_lxc-docker_kernel`（约 21.8 MB），支持 KernelSU + LXC-Docker。

<br>

## 一些修复方法
### k30pro / 一加9R los 内核编译后不生成 Image.gz
在内核配置文件末尾加入：
```
CONFIG_BUILD_ARM64_KERNEL_COMPRESSION_GZIP=y
CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE=y
CONFIG_BUILD_ARM64_DT_OVERLAY=y
```
### .py 文件报 print 语法错误
`env.sh` 中设置 `SWITCH_PYTHON=true` 切换到 Python 2。

<br>

## 感谢
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
