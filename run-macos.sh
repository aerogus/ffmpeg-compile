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
##

SRC_PATH=$HOME/ffmpeg_sources
BUILD_PATH=$HOME/ffmpeg_build
BIN_PATH=$HOME/bin

if [ ! -d "$SRC_PATH" ]; then
  mkdir "$SRC_PATH"
fi
if [ ! -d "$BUILD_PATH" ]; then
  mkdir "$BUILD_PATH"
fi
if [ ! -d "$BIN_PATH" ]; then
  mkdir "$BIN_PATH"
fi

# Téléchargement et décompression de toutes les dépendances externes
# à jour au 01/06/2019

# Dépendances générales"
#yum -y install autoconf automake bzip2 bzip2-devel cmake freetype-devel gcc gcc-c++ git libtool make mercurial pkgconfig zlib-devel
#brew install automake fdk-aac git libass nasm wget libtool x264

# NASM : que pour liblame ??
installNASM() {
  cd "$SRC_PATH" || return
  if [ ! -d "nasm-2.14.02" ]; then
    curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2
    tar xjvf nasm-2.14.02.tar.bz2
  fi
  cd nasm-2.14.02
  ./autogen.sh
  ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH"
  make && make install && make distclean
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
  make install && \
  make distclean
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
  make install && \
  make distclean
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
  make install && \
  make distclean
}

# libass
installLibAss() {
  #yum -y install freebidi freebidi-devel fontconfig fontconfig-devel
  cd "$SRC_PATH" && \
  if [ ! -d "libass" ]; then
    git clone https://github.com/libass/libass.git
  fi
  cd libass && \
  ./autogen.sh && \
  PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
  PATH="$BIN_PATH:$PATH" make && \
  make install && \
  make distclean # à vérifier
}

# ffmpeg
installFfmpeg() {
  cd "$SRC_PATH" || return
  if [ ! -d "ffmpeg-4.1.3" ]; then
    curl -O -L https://ffmpeg.org/releases/ffmpeg-4.1.3.tar.bz2 && \
    tar xjvf ffmpeg-4.1.3.tar.bz2
  fi
  cd ffmpeg-4.1.3 && \
  PATH="$BIN_PATH:$PATH" PKG_CONFIG_PATH="$BUILD_PATH/lib/pkgconfig" ./configure \
    --prefix="$BUILD_PATH" \
    --extra-cflags="-I$BUILD_PATH/include" \
    --extra-ldflags="-L$BUILD_PATH/lib" \
    --bindir="$BIN_PATH" \
    --enable-gpl \
    --enable-nonfree \
    --disable-ffplay \
    --enable-libfreetype \
    --enable-libass \
    --enable-libfdk_aac \
    --enable-libx264
  PATH="$BIN_PATH:$PATH" make && \
  make install && \
  make distclean
}


installNASM
installYasm
installLibX264
installLibFdkAac
#installLibAss
installFfmpeg
