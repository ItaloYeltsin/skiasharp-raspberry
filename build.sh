#!/bin/bash
set -x

# get current script path and use it as the base directory

SCRIPT=$(readlink -f "$0")

export BASE_DIR=$(dirname "$SCRIPT")

export BUILD_DIR=$BASE_DIR/build
export RPI_ROOT=$BASE_DIR/rpi
#install clang?
if false; then

bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"

To install a specific version of LLVM:
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh 9
fi

# clean raspberry root?

if false; then
    sudo apt-get install debootstrap qemu-user-static schroot
    rm -Rf $RPI_ROOT
    mkdir -p $RPI_ROOT
    cd $RPI_ROOT

    sudo qemu-debootstrap --foreign --arch armhf jessie $RPI_ROOT http://ftp.debian.org/debian
fi

#dependencies on rpi
if true; then
    chroot $RPI_ROOT apt -q -y --force-yes install build-essential
    chroot $RPI_ROOT apt -q -y --force-yes install gcc-multilib g++-multilib
    chroot $RPI_ROOT apt -q -y --force-yes install libstdc++-4.8-dev
    chroot $RPI_ROOT apt -q -y --force-yes install libfontconfig1-dev
    chroot $RPI_ROOT apt -q -y --force-yes install libgles2-mesa-dev

fi
# clean build?
if false; then
    sudo apt-get install python python3
    rm -Rf $BUILD_DIR
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR

    git clone https://skia.googlesource.com/skia.git
    cd skia
    git checkout chrome/m71
    git submodule update --init --recursive

    cd $BASE_DIR/skia
    python tools/git-sync-deps

    cd $BASE_DIR
    git clone 'https://chromium.googlesource.com/chromium/tools/depot_tools.git'
    
fi

export PATH="$PATH:$BASE_DIR/depot_tools"
cd $BUILD_DIR/skia
if true; then

    rm -Rf out

    gn gen out/linux/arm --args='
      target_cpu = "arm"
      cc = "clang-9"
      cxx = "clang++-9"
      skia_use_egl= true
      skia_enable_gpu = true
      skia_use_libjpeg_turbo = false
      is_official_build=true
      skia_use_freetype=true
      skia_use_zlib=false
      skia_use_angle = false
      skia_use_expat = false
      skia_use_icu = false
      skia_use_libjpeg_turbo = false
      skia_use_libpng = false
      skia_use_libwebp = false
      skia_use_lua = false
      skia_use_opencl = false
      skia_use_piex = false
      skia_use_zlib = false
      skia_use_metal = false
      skia_enable_flutter_defines = false
      skia_enable_fontmgr_empty = false
      skia_enable_pdf = false
      skia_enable_vulkan_debug_layers = false 
      skia_enable_tools = false
     
      skia_use_icu = false
      skia_use_sfntly = false
      is_debug = false
     
      extra_cflags = [
        "-O3",
        "-target", "armv7a-linux",
        "-mfloat-abi=hard",
        "-mfpu=neon",
        "--sysroot='$RPI_ROOT'",
        "-I'$RPI_ROOT'/usr/include/c++/4.9",
        "-I'$RPI_ROOT'/usr/include/arm-linux-gnueabihf",
        "-I'$RPI_ROOT'/usr/include/arm-linux-gnueabihf/c++/4.9",
        "-I'$RPI_ROOT'/usr/include/freetype2",
        "-DSKIA_C_DLL"
      ]
      extra_asmflags = [
            "-g",
            "-target", "armv7a-linux",
            "-mfloat-abi=hard",
            "-mfpu=neon",
          ]
        '

    ninja -C out/linux/arm

fi

sudo cp $BUILD_DIR/skia/out/linux/arm/libskia.a $BUILD_DIR/

echo built.
