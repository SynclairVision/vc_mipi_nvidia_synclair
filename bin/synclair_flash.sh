#!/bin/bash

# Default values
ENABLE_ENCRYPTION=0
ENABLE_WIFI=0

usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Build and flash custom Jetson Orin image"
    echo ""
    echo "Supported options:"
    echo "-e, --encrypt             Enable disk encryption (default: disabled)"
    echo "-w, --wifi                Enable WiFi driver (default: disabled)"
    echo "-h, --help                Show this help text"
}

# Parse command line arguments
while [ $# != 0 ] ; do
    option="$1"
    shift

    case "${option}" in
    -e|--encrypt)
        # if next arg is present and not another option, treat as key path
        if [[ -n "$1" && "${1:0:1}" != "-" ]]; then
                ENCRYPTION_KEY_PATH="$1"
                ENABLE_ENCRYPTION=1
                shift
        fi                
        ;;
    -w|--wifi)
        ENABLE_WIFI=1
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown option ${option}"
        usage
        exit 1
        ;;
    esac
done

# Edit which file is imported in the pinmux file
file="../dev/dt_files/Orin-jetson orin nano&nx pinmux dp-pinmux.dtsi"
line_number=35
new_line='#include "./tegra234-mb1-bct-gpio-p3767-dp-a03.dtsi"'
sed -i "${line_number}s|.*|$new_line|" "$file"

if [[ "${ENABLE_ENCRYPTION}" == "1" ]]; then
  EKS_IMG_PATH="../dev/conf/eks_t234_encryption.img"
else
  EKS_IMG_PATH="../dev/conf/eks_t234.img"
fi

declare -A files_and_destinations=(
  # pinmux generated files
  ["../dev/dt_files/Orin-jetson orin nano&nx pinmux dp-gpio-default.dtsi"]="../build/Xavier_36.2.0/Linux_for_Tegra/bootloader/tegra234-mb1-bct-gpio-p3767-dp-a03.dtsi"
  ["../dev/dt_files/Orin-jetson orin nano&nx pinmux dp-padvoltage-default.dtsi"]="../build/Xavier_36.2.0/Linux_for_Tegra/bootloader/generic/BCT/tegra234-mb1-bct-padvoltage-p3767-dp-a03.dtsi"
  ["../dev/dt_files/Orin-jetson orin nano&nx pinmux dp-pinmux.dtsi"]="../build/Xavier_36.2.0/Linux_for_Tegra/bootloader/generic/BCT/tegra234-mb1-bct-pinmux-p3767-dp-a03.dtsi"
  # EEPROM
  ["../dev/dt_files/tegra234-mb2-bct-misc-p3767-0000.dts"]="../build/Xavier_36.2.0/Linux_for_Tegra/bootloader/generic/BCT/tegra234-mb2-bct-misc-p3767-0000.dts"
  
  ["../dev/dt_files/tegra234-p3768-0000.dtsi"]="../build/Xavier_36.2.0/Linux_for_Tegra/source/hardware/nvidia/t23x/nv-public/tegra234-p3768-0000.dtsi"

  # Encryption image
  ["${EKS_IMG_PATH}"]="../build/Xavier_36.2.0/Linux_for_Tegra/bootloader/eks_t234.img"
)

# Replace original device tree files with custom ones
for src_file in "${!files_and_destinations[@]}"; do
  dest_file="${files_and_destinations[$src_file]}"
  cp "$src_file" "$dest_file" || exit 1
  echo "Copied $src_file to $dest_file"
done

# Build the device tree files
(. build.sh --dt)

# Update Makefile and kernel config based on WiFi flag
if [[ "${ENABLE_WIFI}" == "1" ]]; then
  sed -i 's/KERNEL_DEF_CONFIG ?= defconfig/KERNEL_DEF_CONFIG ?= menuconfig/' ../build/Xavier_36.2.0/Linux_for_Tegra/source/kernel/Makefile
  cp ../dev/conf/.config ../build/Xavier_36.2.0/Linux_for_Tegra/source/kernel/kernel-jammy-src/.config || exit 1
  (. build.sh --kernel)
else
  echo "WiFi driver: DISABLED"
fi

# Update partition size to the size of our NVME SSD
cp ../dev/conf/flash_l4t_external.xml ../build/Xavier_36.2.0/Linux_for_Tegra/tools/kernel_flash/flash_l4t_external.xml || exit 1
cp ../dev/conf/flash_l4t_nvme_rootfs_enc.xml ../build/Xavier_36.2.0/Linux_for_Tegra/tools/kernel_flash/flash_l4t_nvme_rootfs_enc.xml || exit 1

# Finally, flash the jetson with encryption option
if [[ "${ENABLE_ENCRYPTION}" == "1" ]]; then
  echo "Disk encryption: ENABLED"
  (. flash.sh --encrypt "$ENCRYPTION_KEY_PATH" --all)
else
  echo "Disk encryption: DISABLED"
  (. flash.sh --all)
fi