#!/bin/bash
#
# Compile script for kernel
#

# Initialize flags for options
clean=false
clang=true
aclang=false
nclang=false

# Use getopt for parsing long and short options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--clean)
      clean=true
      shift
      ;;
    -ac|--aospclang)
      aclang=true
      shift
      ;;
    -nc|--neutronclang)
      nclang=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

SECONDS=0 # builtin bash timer

ZIPNAME="[AOSP]-Spiteful-sweet-$(date '+%Y%m%d-%H%M').zip"

export KBUILD_BUILD_USER=vbajs
export KBUILD_BUILD_HOST=tbyool
export ARCH=arm64

if [ "$clang" = true ]; then
	if [ "$aclang" = true ]; then
		echo -e "\nCompiling with AOSP Clang!\n"
		CLANG_URL=$(curl -s https://api.github.com/repos/bachnxuan/aosp_clang_mirror/releases/latest | grep "browser_download_url" | head -n 1 | cut -d '"' -f 4)
		if [ ! -d "$PWD/clang" ]; then
			mkdir clang
			curl -L -O "$CLANG_URL"
			tar -C clang -xf clang-*.tar.gz
		else
			echo "Local clang dir found, will not download clang and using that instead"
		fi
	fi

	if [ "$nclang" = true ]; then
		echo -e "\nCompiling with Neutron Clang!\n"
		CLANG_URL=$(curl -s https://api.github.com/repos/Neutron-Toolchains/clang-build-catalogue/releases/latest | grep "browser_download_url" | head -n 1 | cut -d '"' -f 4)
		if [ ! -d "$PWD/clang" ]; then
			mkdir clang
			curl -L -O "$CLANG_URL"
			tar -C clang -xf neutron-clang-*.tar.zst
		else
			echo "Local clang dir found, will not download clang and using that instead"
		fi
	fi

	$PWD/clang/bin/clang --version | head -n1

	export PATH="$PWD/clang/bin/:$PATH"
	export CROSS_COMPILE=aarch64-linux-gnu-
	export CROSS_COMPILE_COMPAT=arm-linux-gnueabi-

	export LD="ld.lld"
	export LLVM=1
	export LLVM_IAS=1
fi

if [ "$clean" = true ]; then
	rm -rf out
	echo "Cleaned output folder"
fi

echo -e "\nStarting compilation...\n"
make O=out sweet_defconfig
make -j$(nproc --all) O=out

kernel="out/arch/arm64/boot/Image.gz"
dtbo="out/arch/arm64/boot/dtbo.img"
dtb="out/arch/arm64/boot/dtb.img"

if [ ! -f "$kernel" ] || [ ! -f "$dtbo" ] || [ ! -f "$dtb" ]; then
	echo -e "\nCompilation failed!"
	exit 1
fi

echo -e "\nKernel compiled successfully! Zipping up...\n"

if [ -d "$AK3_DIR" ]; then
	cp -r $AK3_DIR AnyKernel3
else
	if ! git clone https://github.com/basamaryan/AnyKernel3 -b master AnyKernel3; then
		echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
		exit 1
	fi
fi
	
sed -i "s/kernel\.string=.*/kernel.string=Spiteful Kernel by @vbajs on github/" AnyKernel3/anykernel.sh
sed -i "s/supported\.versions=.*/supported.versions=11-17/" AnyKernel3/anykernel.sh

cp $kernel AnyKernel3
cp $dtbo AnyKernel3
cp $dtb AnyKernel3
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x .git
cd ..
rm -rf AnyKernel3
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"

exit 0
