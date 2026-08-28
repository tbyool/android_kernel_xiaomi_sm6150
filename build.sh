#!/bin/bash
#
# Compile script for kernel
#

# Initialize flags for options
clean=false
clang=false
gcc=false

# Use getopt for parsing long and short options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--clean)
      clean=true
      shift
      ;;
    -cc|--clang)
      clang=true
      shift
      ;;
    -gc|--gcc)
      gcc=true
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

# For if neither compiler options are passed, default to clang
if [ "$clang" = false ] && [ "$gcc" = false ]; then
	clang=true
fi

if [ "$clang" = true ]; then
	gcc=false
	echo -e "\nCompiling with Clang!\n"
	CLANG_URL=$(curl -s https://api.github.com/repos/bachnxuan/aosp_clang_mirror/releases/latest | grep "browser_download_url" | head -n 1 | cut -d '"' -f 4)
	if [ ! -d "$PWD/clang" ]; then
		mkdir clang
		curl -L -O "$CLANG_URL"
		tar -C clang -xf clang-*.tar.gz
	else
		echo "Local clang dir found, will not download clang and using that instead"
	fi

	$PWD/clang/bin/clang --version | head -n1

	export PATH="$PWD/clang/bin/:$PATH"
	export CROSS_COMPILE=aarch64-linux-gnu-
	export CROSS_COMPILE_COMPAT=arm-linux-gnueabi-

	export LD="ld.lld"
	export LLVM=1
	export LLVM_IAS=1
fi

if [ "$gcc" = true ]; then
	clang=false
	echo -e "\nCompiling with GCC!\n"
	GCC_URLS=$(curl -s "https://api.github.com/repos/mvaisakh/gcc-build/releases/latest" | grep "browser_download_url" | cut -d '"' -f 4 | grep -E "eva-gcc-arm.*\.xz")
	if [ ! -d "$PWD/gcc32" ] && [ ! -d "$PWD/gcc64" ]; then
		for url in $GCC_URLS; do
			curl -L -O "$url"
		done
		for file in eva-gcc-arm*.xz; do
			#The files are actually just plain tarballs named as .xz, do not call xz to decompress
			if [[ "$file" == *arm64* ]]; then
				tar -xf "$file" && mv gcc-arm64 gcc64
			else
				tar -xf "$file" && mv gcc-arm gcc32
			fi
			rm -rf "$file"
		done
	else
		echo "Local gcc dirs found, will not download gcc and using those instead"
	fi

	export GCC64_DIR=$PWD/gcc64
	$GCC64_DIR/bin/aarch64-elf-gcc --version | head -n1
	export GCC32_DIR=$PWD/gcc32
	export KBUILD_COMPILER_STRING="$("$GCC64_DIR/bin/aarch64-elf-gcc" --version | head -n1)"
	export PATH="$GCC64_DIR/bin:$GCC32_DIR/bin:$PATH"
	export CROSS_COMPILE="aarch64-elf-"
	export CROSS_COMPILE_COMPAT="arm-eabi-"

	export CC="aarch64-elf-gcc"
	export LD="$GCC64_DIR/bin/aarch64-elf-ld"
	export AR="aarch64-elf-gcc-ar"
	export AS="aarch64-elf-as"
	export NM="aarch64-elf-nm"
	export OBJCOPY="aarch64-elf-objcopy"
	export OBJDUMP="aarch64-elf-objdump"
	export LLVM=0
	export LLVM_IAS=0
fi

if [ "$clean" = true ]; then
	rm -rf out
	echo "Cleaned output folder"
fi

echo -e "\nStarting compilation...\n"
make O=out sweet_defconfig
if [ "$gcc" = true ]; then
	make O=out gcc-lto.config
fi
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
