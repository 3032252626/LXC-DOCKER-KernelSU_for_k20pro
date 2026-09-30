### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
## 4.14 Zundamon LXC/KernelSU — KameYuki HyperOS4 (OS4.0.0.16) 适配版
## 仅替换 boot 分区的 kernel + dtb；不打包、不刷 dtbo / vendor_dlkm / system_dlkm

### AnyKernel setup
# global properties
properties() { '
kernel.string=Zundamon 4.14 LXC/KernelSU (KameYuki OS4 adapt)
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=raphael
device.name2=raphaelin
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
# boot shell variables
BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
split_boot; # 不解包/不改 ramdisk，避免动到 ROM 原 init
flash_boot; # 仅重打包并写入 boot 分区
## end boot install
