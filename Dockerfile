FROM ubuntu:22.04 AS build-env

ENV ASAN_SYMBOLIZER_PATH="/usr/lib/llvm-16/bin/llvm-symbolizer"
ENV ASAN_OPTIONS="alloc_dealloc_mismatch=0"
ENV UBSAN_OPTIONS="halt_on_error=1:abort_on_error=1"
ENV DEBIAN_FRONTEND="noninteractive"
ENV BUILDCACHE_COMPRESS="true"
ENV BUILDCACHE_DIRECT_MODE="true"
ENV BUILDCACHE_ACCURACY="SLOPPY"
ENV BUILDCACHE_LUA_PATH="/opt/buildcache/share/lua-examples"
ENV PATH="/opt:/opt/node-v18.16.0-linux-x64/bin:/opt/cmake-3.26.3-linux-x86_64/bin:/opt/buildcache/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
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
        g++-11 gcc-11

# INSTALL CLANG
RUN add-apt-repository "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-16 main" && \
    apt-get install -y --no-install-recommends clang-16 lldb-16 lld-16 clangd-16 clang-tidy-16 clang-format-16 clang-tools-16 llvm-16-dev llvm-16-tools libomp-16-dev libc++-16-dev libc++abi-16-dev libclang-common-16-dev libclang-16-dev libclang-cpp16-dev libunwind-16-dev

# INSTALL MOLD LINKER
RUN wget https://github.com/motis-project/mold/releases/download/v1.2.0/mold-linux-amd64 && \
    mkdir -p /opt/mold && \
    mv mold-linux-amd64 /opt/mold/ld && \
    chmod +x /opt/mold/ld

# INSTALL ELM 0.18
RUN wget https://github.com/elm-lang/elm-platform/releases/download/0.18.0-exp/elm-platform-linux-64bit.tar.gz && \
    tar xf elm-platform-linux-64bit.tar.gz -C /opt

# INSTALL CROSS-PLATFORM TOOLCHAINS
RUN wget https://github.com/motis-project/musl-toolchains/releases/download/0.0.10/aarch64-unknown-linux-musl.tar.xz && \
    tar xf aarch64-unknown-linux-musl.tar.xz -C /opt && \
    rm -rf aarch64-unknown-linux-musl.tar.xz && \
    wget https://github.com/motis-project/musl-toolchains/releases/download/0.0.10/arm-unknown-linux-musleabihf.tar.xz && \
    tar xf arm-unknown-linux-musleabihf.tar.xz -C /opt && \
    rm -rf arm-unknown-linux-musleabihf.tar.xz && \
    wget https://github.com/motis-project/musl-toolchains/releases/download/0.0.10/x86_64-multilib-linux-musl.tar.xz && \
    tar xf x86_64-multilib-linux-musl.tar.xz -C /opt && \
    rm -rf x86_64-multilib-linux-musl.tar.xz

# INSTALL NODE JS
RUN wget https://nodejs.org/dist/v18.16.0/node-v18.16.0-linux-x64.tar.xz && \
    tar xf node-v18.16.0-linux-x64.tar.xz -C /opt && \
    rm -rf node-v18.16.0-linux-x64.tar.xz

# INSTALL CMAKE
RUN wget https://github.com/Kitware/CMake/releases/download/v3.26.3/cmake-3.26.3-linux-x86_64.tar.gz &&\
    tar xf cmake-3.26.3-linux-x86_64.tar.gz -C /opt && \
    rm -rf cmake-3.26.3-linux-x86_64.tar.gz

# INSTALL PKG
RUN wget https://github.com/motis-project/pkg/releases/download/v0.14/pkg-linux-amd64 -O /opt/pkg && \
    chmod +x /opt/pkg

# INSTALL BUILDCACHE
RUN wget https://github.com/mbitsnbites/buildcache/releases/download/v0.28.2/buildcache-linux.tar.gz && \
    tar xf buildcache-linux.tar.gz -C /opt && \
    rm -rf buildcache-linux.tar.gz

# ADD BUILD DEBUG TOOLS
RUN apt-get install -y --no-install-recommends tree

# UBUNTU 22.04 IS MISSING BZIP IN THE BASE IMAGE
RUN apt-get install -y --no-install-recommends bzip2

# Install sysconfcpus
# https://github.com/elm-community/elm-webpack-loader/issues/96
RUN apt install build-essential -y --no-install-recommends && \
    cd /opt && \
    git clone https://github.com/obmarg/libsysconfcpus.git && \
    cd libsysconfcpus && \
    ./configure && \
    make && make install

# Replace elm-make to call sysconfcpus before.
RUN cd /opt && \
    mv elm-make elm-make-orig && \
    printf "#\041/bin/bash\n\necho \"Running elm-make with sysconfcpus -n 2\"\n\n/usr/local/bin/sysconfcpus -n 2 /opt/elm-make-orig \"\$@\"" > elm-make && \
    chmod +x elm-make
