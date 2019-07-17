#!/usr/bin/env bash

##
# Script de compilation ffmpeg avec les modules qui vont bien
#
# @see https://gist.github.com/Brainiarc7/3f7695ac2a0905b05c5b
#
# Version MacOS
#
# Buts:
# - build static et dynamic
#
# Versions:
# - NASM 2.14.02 (utile que pour lame ?)
# - Yasm 1.3.0
#
# Modules activés :
# - libfdk_aac (Fraunhofer FDK AAC)
# - libass (sous-titrage)
# - libx264
# - libfreetype (pour drawtext)
# - libfontconfig (fallback font par défaut)
# - libx265
##

# installation locale
SRC_PATH=$HOME/ffmpeg_sources
BUILD_PATH=$HOME/ffmpeg_build
BIN_PATH=$HOME/bin
FFMPEG_ENABLE="--enable-gpl --enable-nonfree --disable-ffplay"

# installation globale
#SRC_PATH=/usr/local/src
#BUILD_PATH=/usr/local
#BIN_PATH=/usr/local/bin

if [ ! -d "$SRC_PATH" ]; then
  mkdir "$SRC_PATH"
fi
if [ ! -d "$BUILD_PATH" ]; then
  mkdir "$BUILD_PATH"
fi
if [ ! -d "$BIN_PATH" ]; then
  mkdir "$BIN_PATH"
fi

# libSDL2 nécessaire pour compiler ffplay
# note: pas dispo dans base ni epel
installLibSDL2() {
  echo "* installLibSDL2 *"
  cd "$SRC_PATH" || return
  if [ ! -d "SDL2-2.0.9" ]; then
    curl -O -L http://www.libsdl.org/release/SDL2-2.0.9.tar.gz && \
    tar fvxz SDL2-2.0.9.tar.gz && \
    rm tar fvxz SDL2-2.0.9.tar.gz
  fi
  cd SDL2-2.0.9 && \
  PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
  make && \
  make install
  #make distclean
}

enableFfplay() {
  echo "* enableFfplay *"
  installLibSDL2
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-ffplay"
}

# NASM : que pour liblame ??
installNASM() {
  cd "$SRC_PATH" || return
  if [ ! -d "nasm-2.14.02" ]; then
    curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2
    tar xjvf nasm-2.14.02.tar.bz2
  fi
  cd nasm-2.14.02
  ./autogen.sh
  ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
  make && \
  make install
  #make distclean
}

# Yasm
installYasm() {
  cd "$SRC_PATH" || return
  if [ ! -d "yasm-1.3.0" ]; then
    curl -O -L http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
    tar xzvf yasm-1.3.0.tar.gz
  fi
  cd yasm-1.3.0 && \
  ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
  make && \
  make install
  #make distclean
}

# libx264
installLibX264() {
  cd "$SRC_PATH" || return
  if [ ! -d "x264" ]; then
    git clone --depth 1 http://git.videolan.org/git/x264
  fi
  cd x264 && \
  PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
  PATH="$BIN_PATH:$PATH" make && \
  make install
  #make distclean
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libx264"
}

# libx265
installLibX265() {
  cd "$SRC_PATH" || return
  if [ ! -d "x265" ]; then
    brew install mercurial x265
    hg clone https://bitbucket.org/multicoreware/x265
  fi
  #cd x265/build/linux && \
  #PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
  #PATH="$BIN_PATH:$PATH" make && \
  #make install
  #make distclean
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libx265"
}

# fdk_aac
installLibFdkAac() {
  cd "$SRC_PATH" || return
  if [ ! -d "fdk-aac" ]; then
    git clone --depth 1 https://github.com/mstorsjo/fdk-aac
  fi
  cd fdk-aac && \
  autoreconf -fiv && \
  ./configure --prefix="$BUILD_PATH" --disable-shared && \
  make && \
  make install
  #make distclean
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libfdk_aac"
}

# libass
installLibAss() {
  cd "$SRC_PATH" && \
  if [ ! -d "libass" ]; then
    git clone https://github.com/libass/libass.git
  fi
  cd libass && \
  ./autogen.sh && \
  PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
  PATH="$BIN_PATH:$PATH" make && \
  make install
  #make distclean
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libfreetype --enable-libass"
}

# ffmpeg
installFfmpeg() {
  cd "$SRC_PATH" || return
  if [ ! -d "ffmpeg-4.1.4" ]; then
    curl -O -L https://ffmpeg.org/releases/ffmpeg-4.1.4.tar.bz2 && \
    tar xjvf ffmpeg-4.1.4.tar.bz2
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
  #make distclean
}

brew install automake pkg-config

installNASM
installYasm
installLibX264
installLibX265
installLibFdkAac
installLibAss
installFfmpeg

