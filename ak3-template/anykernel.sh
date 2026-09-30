### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
##
## Universal GKI flash template (installed by the build pipeline over the upstream
## WildKernels script before packaging):
##   - no boot/kernel version check (do.check_boot_version=0)
##   - no Android system version restriction (supported.versions cleared):
##     one kernel zip flashes on Android 12/13/14/15/16/17 systems alike
##   - only rule: the zip's kernel version must match the GKI kernel version the
##     device is currently running (e.g. a 5.10.x zip on a 5.10 GKI device)

### AnyKernel setup
# global properties
properties() { '
kernel.string=GKI Kernel (KernelSU + SUSFS) - Universal Android 12-17
do.devicecheck=0
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
do.check_boot_version=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
keycheck.timeout=10
'; } # end properties


### AnyKernel install
## boot shell variables
block=boot
is_slot_device=auto
ramdisk_compression=auto
patch_vbmeta_flag=auto
no_magisk_check=1

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh

# Environment hint only - never fatal: in a recovery/installer the kernel that runs
# here is the installer kernel, not necessarily the ROM's kernel. The list covers
# every GKI line this repo builds (5.10/5.15/6.1/6.6/6.12) plus the Android 17 GKI
# kernel (6.18, refs/heads/android17-6.18 on AOSP) and interim mainline-based
# kernels (6.16/6.17) so newer installer environments don't block.
kernel_version=$(cat /proc/version | awk -F '-' '{print $1}' | awk '{print $3}')
case $kernel_version in
    5.10*|5.15*|6.1*|6.6*|6.12*|6.16*|6.17*|6.18*) ksu_supported=true ;;
    *) ksu_supported=false ;;
esac

if [ "$ksu_supported" != true ]; then
    ui_print " " "  -> WARNING: running kernel ($kernel_version) is not a known GKI version."
    ui_print "  -> Continuing anyway (version checks are disabled in this package)."
else
    ui_print " " "  -> GKI environment detected: $kernel_version"
fi

# boot install
split_boot

# Android 13+ GKI devices keep the generic ramdisk in init_boot, so their `boot` partition has
# none: flash the kernel only and leave init_boot / vendor_boot alone. Devices whose boot still
# carries a ramdisk take the normal unpack_ramdisk + write_boot path.
if [ -s "$SPLITIMG/ramdisk.cpio" ]; then
    unpack_ramdisk
    write_boot
else
    ui_print " " "  -> boot has no ramdisk (init_boot layout), kernel-only flash"
    flash_boot
fi

ui_print " "
ui_print "  -> Universal GKI package: system version agnostic (Android 12-17)."
ui_print "     Kernel must match the device's GKI kernel version (e.g. 5.10.x)."
ui_print " "
