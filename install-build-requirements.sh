#!/bin/bash

# Function to print the command that failed
trap 'echo "Error: Command failed at line $LINENO: $BASH_COMMAND"' ERR

set -e

sudo yum install -y centos-release-scl

# install devtoolset-8 (recommended)
sudo yum install -y devtoolset-8-gcc devtoolset-8-gcc-c++ devtoolset-8-make devtoolset-8-elfutils-libelf-devel devtoolset-8-systemtap-sdt-devel

# shellcheck disable=SC3046
# shellcheck disable=SC1091
source scl_source enable devtoolset-8 || true

sudo yum install -y ncurses-devel git which

# install JDK 1.8
sudo yum install -y java-1.8.0-openjdk-devel

# Install build tools

# Download and extract CMake
export CMAKE_VERSION=3.26.3
curl -L https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-linux-x86_64.tar.gz -o cmake-$CMAKE_VERSION-linux-x86_64.tar.gz
tar -xzvf cmake-$CMAKE_VERSION-linux-x86_64.tar.gz
sudo cp -fR cmake-$CMAKE_VERSION-linux-x86_64/* /usr
rm -rf cmake-$CMAKE_VERSION-linux-x86_64 cmake-$CMAKE_VERSION-linux-x86_64.tar.gz

# Download and extract Ninja
export NINJA_VERSION=1.11.1
curl -L https://github.com/ninja-build/ninja/archive/refs/tags/v$NINJA_VERSION.tar.gz -o ninja-$NINJA_VERSION.tar.gz
tar -xzvf ninja-$NINJA_VERSION.tar.gz
cd ninja-$NINJA_VERSION
cmake -Bbuild-cmake
cmake --build build-cmake
sudo mv build-cmake/ninja /usr/bin/ninja
cd ..
rm -rf ninja-$NINJA_VERSION ninja-$NINJA_VERSION.tar.gz

sudo yum install -y ant libtool libtool-ltdl autoconf automake rpm-build
sudo yum install -y flex

# Download and extract Bison
export BISON_VERSION=3.0.5
curl -L https://ftp.gnu.org/gnu/bison/bison-$BISON_VERSION.tar.gz -o bison-$BISON_VERSION.tar.gz
tar -xzvf bison-$BISON_VERSION.tar.gz
cd bison-$BISON_VERSION
sudo ./configure --prefix=/usr
sudo make all install
cd ..
sudo rm -rf bison-$BISON_VERSION bison-$BISON_VERSION.tar.gz

