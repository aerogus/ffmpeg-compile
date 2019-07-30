#!/usr/bin/env bash

# test avec la debian 9 rbx.aerogus.net

# NASM : OK
# Yasm : OK
# libx264 : OK
# libfdk_aac : OK

SRC_PATH=$HOME/ffmpeg_sources
BUILD_PATH=$HOME/ffmpeg_build
BIN_PATH=$HOME/bin
FFMPEG_ENABLE="--enable-gpl --enable-nonfree --disable-ffplay"

if [ ! -d "$SRC_PATH" ]; then
  mkdir "$SRC_PATH"
fi
if [ ! -d "$BUILD_PATH" ]; then
  mkdir "$BUILD_PATH"
fi
if [ ! -d "$BIN_PATH" ]; then
  mkdir "$BIN_PATH"
fi

apt-get install autoconf automake bzip2 bzip2-devel cmake freetype-devel gcc gcc-c++ git libtool make mercurial pkgconfig zlib-devel

# NASM : que pour liblame ??
installNASM() {
  cd "$SRC_PATH" || return
  if [ ! -d "nasm-2.14.02" ]; then
    curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2
    tar xjvf nasm-2.14.02.tar.bz2
  fi
  cd nasm-2.14.02 && \
  ./autogen.sh && \
  ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
  make && \
  make install
}

# Yasm
installYasm() {
  echo "* install Yasm *"
  cd "$SRC_PATH" || return
  if [ ! -d "yasm-1.3.0" ]; then
    curl -O -L http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz && \
    tar xzvf yasm-1.3.0.tar.gz && \
    rm yasm-1.3.0.tar.gz
  fi
  cd yasm-1.3.0 && \
  PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
  make && \
  make install
}

# libx264
installLibX264() {
  echo "* installLibX264 *"
  cd "$SRC_PATH" || return
  if [ ! -d "x264" ]; then
    git clone --depth 1 http://git.videolan.org/git/x264
  fi
  cd x264 && \
  PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
  PATH="$BIN_PATH:$PATH" make && \
  make install
}

enableLibX264() {
  echo "* enableLibX264 *"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libx264"
}

installLibX265() {
  echo "* installLibX265 *"
  cd "$SRC_PATH" || return
  if [ ! -d "x265" ]; then
    brew install mercurial x265
    hg clone https://bitbucket.org/multicoreware/x265
  fi
  cd x265/build/linux && \
  PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
  PATH="$BIN_PATH:$PATH" make && \
  make install
}

enableLibX265() {
  echo "* enableLibX265 *"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libx265"
}

# fdk_aac
installLibFdkAac() {
  echo "* installLibFdkAac *"
  cd "$SRC_PATH" || return
  if [ ! -d "fdk-aac" ]; then
    git clone --depth 1 https://github.com/mstorsjo/fdk-aac
  fi
  cd fdk-aac && \
  autoreconf -fiv && \
  ./configure --prefix="$BUILD_PATH" --disable-shared && \
  make && \
  make install
}

enableLibFdkAac() {
  echo "* enableLibFdkAac *"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libfdk_aac"
}

# ffmpeg
installFfmpeg() {
  echo "* installFfmpeg *"
  cd "$SRC_PATH" || return
  if [ ! -d "ffmpeg-4.1.4" ]; then
    curl -O -L https://ffmpeg.org/releases/ffmpeg-4.1.4.tar.bz2 && \
    tar xjvf ffmpeg-4.1.4.tar.bz2 && \
    rm ffmpeg-4.1.4.tar.bz2
  fi
  cd ffmpeg-4.1.4 && \
  PATH="$BIN_PATH:$PATH" PKG_CONFIG_PATH="$BUILD_PATH/lib/pkgconfig" ./configure \
    --prefix="$BUILD_PATH" \
    --extra-cflags="-I$BUILD_PATH/include" \
    --extra-ldflags="-L$BUILD_PATH/lib" \
    --bindir="$BIN_PATH" \
    ${FFMPEG_ENABLE} && \
  PATH="$BIN_PATH:$PATH" make && \
  make install
}

installNASM
installYasm

installLibX264
#installLibX265
installLibFdkAac

enableLibX264
#enableLibX265
enableLibFdkAac

installFfmpeg
