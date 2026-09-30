# OS4 适配打包资源（自用）

面向 **KameYuki HyperOS4 / OS4.0.0.16 (raphael / raphaelin)** 的内核卡刷包打包资源。
工作流 `build-raphael-4.14-replica.yml` 勾选 `os4_adapt=true` 时使用本目录文件。

## 文件

| 文件 | 说明 |
|---|---|
| `raphael_kameyuki_os4_rom.dtb` | ROM 原 dtb，提取自 `OS4.0.0.16_KameYuki/firmware-update` 体系内的 `kernel/kernel_image.bin` 尾部 appended FDT |
| `anykernel-os4.sh` | OS4 专用 anykernel.sh：仅 `split_boot` + `flash_boot`，不刷 dtbo |

## ROM 原 dtb 校验

```
size    : 446802 B
sha256  : 30bb3fc900a02e221b0e8190a5b68458e6ab254248d4419b4694001226bf0288
FDT     : magic d00dfeed, totalsize 446802
```

提取方式（可复现）：

```python
import hashlib
d = open("kernel_image.bin", "rb").read()   # ROM boot.img 拆出的 kernel 段
i = d.rfind(b"\xd0\x0d\xfe\xed")            # 最后一个 FDT magic
dtb = d[i:]
assert len(dtb) == 446802
print(hashlib.sha256(dtb).hexdigest())
```

## 打包行为（os4_adapt=true）

1. 取编译产物 `Image.gz`（不含 dtb），尾部追加本目录 ROM 原 dtb → `Image.gz-dtb`；
2. 不构建、不打包 `dtbo.img`（dtbo 分区保持 ROM 原样）；
3. `anykernel.sh` 替换为 `anykernel-os4.sh`，并注释掉 `tools/ak3-core.sh` 中 `flash_generic dtbo;`（双保险）；
4. `LOCALVERSION` 不做任何改动。

默认（`os4_adapt=false`）行为与改动前完全一致：自编译 `sm8150-v2.dtb` + `dtbo.img`。
