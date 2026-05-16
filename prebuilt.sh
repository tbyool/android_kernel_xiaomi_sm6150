#!/bin/bash
#
# Prebuilt kernel tree export script
# Copyright (C) 2026 Richard R.

set -euo pipefail

trap 'printf "\nInterrupted.\n"; exit 1' INT

REMOTE="git@github.com:tbyool/device_xiaomi_sweet-kernel.git"

kernel="out/arch/arm64/boot/Image.gz"
dtb="out/arch/arm64/boot/dtb.img"
dtbo="out/arch/arm64/boot/dtbo.img"

if [ ! -f "$kernel" ] || [ ! -f "$dtb" ] || [ ! -f "$dtbo" ]; then
	printf "Missing build artifacts, run build.sh first.\n"
	exit 1
fi

if [ ! -d out/usr/include ]; then
	printf "Missing kernel headers, run build.sh first.\n"
	exit 1
fi

rm -rf out/prebuilt
mkdir -p out/prebuilt/kernel-headers
mkdir -p out/prebuilt/kernel-headers/techpack
cp "$kernel" "$dtb" "$dtbo" out/prebuilt
cp -r out/usr/include/. out/prebuilt/kernel-headers
# Because techpack headers is broken in this kernel, fix it manually
cp -r out/usr/audio out/usr/data out/usr/stub out/prebuilt/kernel-headers/techpack

cat > out/prebuilt/Android.bp << 'EOF'
kernel_headers {
	name: "qti_kernel_headers",
	recovery_available: true,
	vendor_available: true
}
EOF

INFO="http://github.com/tbyool/android_kernel_xiaomi_sm6150/tree/$(git rev-parse --verify HEAD)"

	git -C out/prebuilt init -q
	git -C out/prebuilt checkout -qb staging
	git -C out/prebuilt add -A
	git -C out/prebuilt commit -q -m "sweet-kernel: Import prebuilt artifacts $(date '+%Y%m%d-%H%M')" -m "$INFO"
	git -C out/prebuilt push -qf "$REMOTE" staging

printf "%s\nPrebuilt artifacts exported successfully.\n" "$INFO"
