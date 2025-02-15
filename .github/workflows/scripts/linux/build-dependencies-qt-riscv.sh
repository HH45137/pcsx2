#!/usr/bin/env bash

# Use method: .github/workflows/scripts/linux/build-dependencies-qt-riscv.sh deps-riscv <riscv-toolchain-path>

set -e

function check_and_download() {
    if [ $# -lt 1 -o $# -gt 2 ]; then
        echo "Usage: check_and_download [filename] url"
        return 1
    fi
    if [ $# -eq 1 ]; then
        url="$1"
        filename=$(basename $url)
    else
        filename="$1"
        url="$2"
    fi
    if [ -e "$filename" ]; then
        echo "file $filename is found, not downloading"
    else
        wget "$url" -O "$filename"
    fi
}

if [ "$#" -ne 2 ]; then
    echo "Syntax: $0 <output directory>"
    exit 1
fi

SCRIPTDIR=$(realpath $(dirname "${BASH_SOURCE[0]}"))
NPROCS="$(getconf _NPROCESSORS_ONLN)"
INSTALLDIR="$1"
if [ "${INSTALLDIR:0:1}" != "/" ]; then
	INSTALLDIR="$PWD/$INSTALLDIR"
fi
echo $INSTALLDIR

LIBBACKTRACE=ad106d5fdd5d960bd33fae1c48a351af567fd075
LIBJPEG=9f
LIBPNG=1.6.45
LIBWEBP=1.5.0
LZ4=b8fd2d15309dd4e605070bd4486e26b6ef814e29
SDL=SDL2-2.30.12
QT=6.8.2
ZSTD=1.5.6

SHADERC=2024.1
SHADERC_GLSLANG=142052fa30f9eca191aa9dcf65359fcaed09eeec
SHADERC_SPIRVHEADERS=5e3ad389ee56fca27c9705d093ae5387ce404df4
SHADERC_SPIRVTOOLS=dd4b663e13c07fea4fbb3f70c1c91c86731099f7

BASE_PROJ_SRC_DIR="$SCRIPTDIR/../../../../"
BASE_DEPS_BUILD_DIR_NAME=deps-build-riscv
BASE_DEPS_BUILD_DIR="$BASE_PROJ_SRC_DIR/$BASE_DEPS_BUILD_DIR_NAME/"
BASE_DEPS_DST_DIR_NAME=$1
BASE_DEPS_DST_DIR="$BASE_PROJ_SRC_DIR/$BASE_DEPS_DST_DIR_NAME"


mkdir -p $BASE_DEPS_BUILD_DIR && cd $BASE_DEPS_BUILD_DIR


check_and_download "https://zlib.net/zlib-1.3.1.tar.xz"
check_and_download "zstd-dev.zip" "https://github.com/facebook/zstd/archive/refs/heads/dev.zip"
check_and_download "https://github.com/ianlancetaylor/libbacktrace/archive/$LIBBACKTRACE.zip" 
check_and_download "https://ijg.org/files/jpegsrc.v$LIBJPEG.tar.gz" 
check_and_download "https://downloads.sourceforge.net/project/libpng/libpng16/$LIBPNG/libpng-$LIBPNG.tar.xz" 
check_and_download "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$LIBWEBP.tar.gz" 
check_and_download "https://github.com/lz4/lz4/archive/$LZ4.tar.gz" 
check_and_download "https://libsdl.org/release/$SDL.tar.gz" 
check_and_download "https://github.com/facebook/zstd/releases/download/v$ZSTD/zstd-$ZSTD.tar.gz" 
check_and_download "https://download.qt.io/official_releases/qt/${QT%.*}/$QT/submodules/qtbase-everywhere-src-$QT.tar.xz" 
check_and_download "https://download.qt.io/official_releases/qt/${QT%.*}/$QT/submodules/qtimageformats-everywhere-src-$QT.tar.xz" 
check_and_download "https://download.qt.io/official_releases/qt/${QT%.*}/$QT/submodules/qtsvg-everywhere-src-$QT.tar.xz" 
check_and_download "https://download.qt.io/official_releases/qt/${QT%.*}/$QT/submodules/qttools-everywhere-src-$QT.tar.xz" 
check_and_download "https://download.qt.io/official_releases/qt/${QT%.*}/$QT/submodules/qttranslations-everywhere-src-$QT.tar.xz" 
check_and_download "https://download.qt.io/official_releases/qt/${QT%.*}/$QT/submodules/qtwayland-everywhere-src-$QT.tar.xz" 
check_and_download "shaderc-$SHADERC.tar.gz" "https://github.com/google/shaderc/archive/refs/tags/v$SHADERC.tar.gz" 
check_and_download "shaderc-glslang-$SHADERC_GLSLANG.tar.gz" "https://github.com/KhronosGroup/glslang/archive/$SHADERC_GLSLANG.tar.gz" 
check_and_download "shaderc-spirv-headers-$SHADERC_SPIRVHEADERS.tar.gz" "https://github.com/KhronosGroup/SPIRV-Headers/archive/$SHADERC_SPIRVHEADERS.tar.gz" 
check_and_download "shaderc-spirv-tools-$SHADERC_SPIRVTOOLS.tar.gz" "https://github.com/KhronosGroup/SPIRV-Tools/archive/$SHADERC_SPIRVTOOLS.tar.gz"


export PATH="$2:$PATH"
export CC="riscv64-unknown-elf-gcc"
export CXX="riscv64-unknown-elf-g++"
export HOST="riscv64-unknown-elf"
export BUILD="x86_64-pc-linux-gnu"
export AR="riscv64-unknown-elf-ar"
export RANLIB="riscv64-unknown-elf-ranlib"


cd $BASE_DEPS_BUILD_DIR

echo "Building libbacktrace..."
rm -fr "libbacktrace-$LIBBACKTRACE"
unzip "$LIBBACKTRACE.zip"
cd "libbacktrace-$LIBBACKTRACE"
./configure CC="$CC" --host="$HOST" --build="$BUILD" --prefix="$INSTALLDIR"
make "-j$NPROCS"
make install

cd $BASE_DEPS_BUILD_DIR

echo "Building zlib..."
rm -fr zlib-1.3.1
tar xvf zlib-1.3.1.tar.xz
cd zlib-1.3.1
CC=$CC AR=$AR RANLIB=$RANLIB ./configure --prefix=$INSTALLDIR
make "-j$NPROCS"
make install

cd $BASE_DEPS_BUILD_DIR

echo "Building libpng..."
rm -fr "libpng-$LIBPNG"
tar xf "libpng-$LIBPNG.tar.xz"
cd "libpng-$LIBPNG"
cmake -DCMAKE_TOOLCHAIN_FILE="$SCRIPTDIR/riscv64-toolchain.cmake" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DBUILD_SHARED_LIBS=ON -DBUILD_SHARED_LIBS=ON -DPNG_TESTS=OFF -DPNG_STATIC=OFF -DPNG_SHARED=ON -DPNG_TOOLS=OFF -B build -G Ninja
cmake --build build --parallel
ninja -C build install

cd $BASE_DEPS_BUILD_DIR

echo "Building libjpeg..."
rm -fr "jpeg-$LIBJPEG"
tar xf "jpegsrc.v$LIBJPEG.tar.gz"
cd "jpeg-$LIBJPEG"
mkdir build
cd build
../configure CC="$CC" --host="$HOST" --build="$BUILD" --prefix="$INSTALLDIR" --disable-static --enable-shared
make "-j$NPROCS"
make install

cd $BASE_DEPS_BUILD_DIR

echo "Building LZ4..."
rm -fr "lz4-$LZ4"
tar xf "$LZ4.tar.gz"
cd "lz4-$LZ4"
cmake -DCMAKE_TOOLCHAIN_FILE="$SCRIPTDIR/riscv64-toolchain.cmake" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DBUILD_SHARED_LIBS=ON -DLZ4_BUILD_CLI=OFF -DLZ4_BUILD_LEGACY_LZ4C=OFF -B build-dir -G Ninja build/cmake
cmake --build build-dir --parallel
ninja -C build-dir install

cd $BASE_DEPS_BUILD_DIR

# echo "Building Zstandard..."
# rm -fr "zstd-dev"
# unzip "zstd-dev.zip"
# cd "zstd-dev"
# make CC="$CC" AR="$AR" RANLIB="$RANLIB" PREFIX="$INSTALLDIR" zstd

cd $BASE_DEPS_BUILD_DIR


readelf -h $BASE_PROJ_SRC_DIR/deps-riscv/lib/*.* | grep -E 'Class|Machine'
