#!/bin/bash

# Check if a mode is provided
if [ -z "$1" ]; then
  echo "Usage: $0 [local|workstation]"
  exit 1
fi

MODE=$1

# Define the file to be edited
file="Orin-jetson orin nano&nx pinmux dp-pinmux.dtsi"

# Define the line number and the new line content
line_number=35
new_line='#include "./tegra234-mb1-bct-gpio-p3767-dp-a03.dtsi"'

# Use sed to replace the specific line
sed -i "${line_number}s|.*|$new_line|" "$file"

# Define the source files and their respective destinations based on the mode
if [ "$MODE" = "local" ]; then
  declare -A files_and_destinations=(
    ["Orin-jetson orin nano&nx pinmux dp-gpio-default.dtsi"]="/home/fredrik/vc_mipi_nvidia/build/Xavier_35.3.1/Linux_for_Tegra/bootloader/tegra234-mb1-bct-gpio-p3767-dp-a03.dtsi"
    ["Orin-jetson orin nano&nx pinmux dp-padvoltage-default.dtsi"]="/home/fredrik/vc_mipi_nvidia/build/Xavier_35.3.1/Linux_for_Tegra/bootloader/t186ref/BCT/tegra234-mb1-bct-padvoltage-p3767-dp-a03.dtsi"
    ["Orin-jetson orin nano&nx pinmux dp-pinmux.dtsi"]="/home/fredrik/vc_mipi_nvidia/build/Xavier_35.3.1/Linux_for_Tegra/bootloader/t186ref/BCT/tegra234-mb1-bct-pinmux-p3767-dp-a03.dtsi"
  )
elif [ "$MODE" = "workstation" ]; then
  declare -A files_and_destinations=(
    ["Orin-jetson orin nano&nx pinmux dp-gpio-default.dtsi"]="~/fredrik/vc_mipi_nvidia/build/Xavier_35.3.1/Linux_for_Tegra/bootloader/tegra234-mb1-bct-gpio-p3767-dp-a03.dtsi"
    ["Orin-jetson orin nano&nx pinmux dp-padvoltage-default.dtsi"]="~/fredrik/vc_mipi_nvidia/build/Xavier_35.3.1/Linux_for_Tegra/bootloader/t186ref/BCT/tegra234-mb1-bct-padvoltage-p3767-dp-a03.dtsi"
    ["Orin-jetson orin nano&nx pinmux dp-pinmux.dtsi"]="~/fredrik/vc_mipi_nvidia/build/Xavier_35.3.1/Linux_for_Tegra/bootloader/t186ref/BCT/tegra234-mb1-bct-pinmux-p3767-dp-a03.dtsi"
  )
else
  echo "Invalid mode: $MODE. Use either 'local' or 'workstation'."
  exit 1
fi

# Perform the file copy operations based on the mode
if [ "$MODE" = "local" ]; then
  echo "Running in local mode..."
  for src_file in "${!files_and_destinations[@]}"; do
    dest_file="${files_and_destinations[$src_file]}"
    cp "$src_file" "$dest_file"
    echo "Copied $src_file to $dest_file locally."
  done
elif [ "$MODE" = "workstation" ]; then
  echo "Running in workstation mode..."
  for src_file in "${!files_and_destinations[@]}"; do
    dest_file="${files_and_destinations[$src_file]}"
    scp "$src_file" "synclairuser@192.168.1.192:$dest_file"
    echo "Copied $src_file to $dest_file on workstation."
  done
fi
