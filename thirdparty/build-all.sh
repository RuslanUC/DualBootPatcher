#!/bin/bash

export PATH=$PATH:$NDK_R18B

mkdir -p prebuilts-local
cd prebuilts-local
python -m http.server 9898 &
PYTHON_SERVER_PID=$!
cd ..

stop_python() {
  echo "Waiting for python http server to stop..."

  kill -s TERM $PYTHON_SERVER_PID
  wait $PYTHON_SERVER_PID
}

trap stop_python EXIT

build_package() {
  local package_name=$1

  cd "$package_name"
  local pkgname=$(cat PKGBUILD | grep "pkgname=" | cut -d'=' -f2)
  if [[ $pkgname == "("* ]]; then
    pkgname=$(cat PKGBUILD | grep "pkgbase=" | cut -d'=' -f2)
  fi

  for crossarch in armv7 aarch64 x86 x86_64;
  do
    ls $pkgname-*-$crossarch.pkg.tar.gz >/dev/null 2>/dev/null && { echo "Package $package_name for $crossarch already built"; continue; }
    CARCH=$crossarch ANDROID_NDK_HOME=$NDK_R18B ../makepkg -c -C || { echo "Failed to build $package_name"; exit 1; }

    echo "Built $package_name for $crossarch"
  done

  cp *.pkg.tar.gz ../prebuilts-local/
  cd ..
}

build_package "boringssl"
build_package "exfat"
build_package "fuse"
build_package "libdrm"
build_package "liblzma"
build_package "libpng"
build_package "freetype2"
build_package "libsepol"
build_package "lz4"
build_package "libarchive"
build_package "safe-iop"
build_package "android-system-core"
build_package "strace"
build_package "test-runner-image"
#build_package "valgrind"
