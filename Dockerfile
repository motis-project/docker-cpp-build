FROM ubuntu:24.04 AS build-env

ENV ASAN_SYMBOLIZER_PATH="/usr/lib/llvm-21/bin/llvm-symbolizer"
ENV ASAN_OPTIONS="alloc_dealloc_mismatch=0"
ENV UBSAN_OPTIONS="halt_on_error=1:abort_on_error=1"
ENV DEBIAN_FRONTEND="noninteractive"
ENV BUILDCACHE_COMPRESS="true"
ENV BUILDCACHE_DIRECT_MODE="true"
ENV BUILDCACHE_ACCURACY="SLOPPY"
ENV BUILDCACHE_LUA_PATH="/opt/buildcache/share/lua-examples"
ENV PATH="/opt:/opt/node-v24.11.0-linux-x64/bin:/opt/cmake-3.30.3-linux-x86_64/bin:/opt/buildcache/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# BASE SETUP
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get install -y --no-install-recommends software-properties-common xz-utils wget gnupg2 ca-certificates software-properties-common && \
    wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        netbase \
        git wget gnupg2 \
        valgrind \
        ninja-build qemu-user-static \
        g++-13 gcc-13

# INSTALL CLANG
RUN add-apt-repository "deb http://apt.llvm.org/noble/ llvm-toolchain-noble-21 main" && \
    apt-get install -y --no-install-recommends clang-21 lldb-21 lld-21 clangd-21 clang-tidy-21 clang-format-21 clang-tools-21 llvm-21-dev llvm-21-tools libomp-21-dev libc++-21-dev libc++abi-21-dev libclang-common-21-dev libclang-21-dev libclang-cpp21-dev libunwind-21-dev libclang-rt-21-dev

# INSTALL MOLD LINKER
RUN wget https://github.com/motis-project/mold/releases/download/v1.2.0/mold-linux-amd64 && \
    mkdir -p /opt/mold && \
    mv mold-linux-amd64 /opt/mold/ld && \
    chmod +x /opt/mold/ld

# INSTALL CROSS-PLATFORM TOOLCHAINS
RUN wget https://github.com/motis-project/musl-toolchains/releases/download/v0.0.14/aarch64-unknown-linux-musl.tar.xz && \
    tar xf aarch64-unknown-linux-musl.tar.xz -C /opt && \
    rm -rf aarch64-unknown-linux-musl.tar.xz && \
    wget https://github.com/motis-project/musl-toolchains/releases/download/v0.0.14/arm-unknown-linux-musleabihf.tar.xz && \
    tar xf arm-unknown-linux-musleabihf.tar.xz -C /opt && \
    rm -rf arm-unknown-linux-musleabihf.tar.xz && \
    wget https://github.com/motis-project/musl-toolchains/releases/download/v0.0.14/x86_64-multilib-linux-musl.tar.xz && \
    tar xf x86_64-multilib-linux-musl.tar.xz -C /opt && \
    rm -rf x86_64-multilib-linux-musl.tar.xz

# INSTALL NODE JS
RUN wget https://nodejs.org/dist/v24.11.0/node-v24.11.0-linux-x64.tar.xz && \
    tar xf node-v24.11.0-linux-x64.tar.xz -C /opt && \
    rm -rf node-v24.11.0-linux-x64.tar.xz

# INSTALL CMAKE
RUN wget https://github.com/Kitware/CMake/releases/download/v3.30.3/cmake-3.30.3-linux-x86_64.tar.gz &&\
    tar xf cmake-3.30.3-linux-x86_64.tar.gz -C /opt && \
    rm -rf cmake-3.30.3-linux-x86_64.tar.gz

# INSTALL PKG
RUN wget https://github.com/motis-project/pkg/releases/download/v0.22/pkg-linux-amd64 -O /opt/pkg && \
    chmod +x /opt/pkg

# INSTALL BUILDCACHE
RUN wget https://gitlab.com/bits-n-bites/buildcache/-/releases/v0.31.7/downloads/buildcache-linux-amd64.tar.gz && \
    tar xf buildcache-linux.tar.gz -C /opt && \
    rm -rf buildcache-linux.tar.gz

# ADD BUILD DEBUG TOOLS
RUN apt-get install -y --no-install-recommends tree

# UBUNTU 22.04 IS MISSING BZIP IN THE BASE IMAGE
RUN apt-get install -y --no-install-recommends bzip2

# CLEAN UP
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
