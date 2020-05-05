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
# - libndi_newtek
##

# installation locale
SRC_PATH=$HOME/ffmpeg_sources
BUILD_PATH=$HOME/ffmpeg_build
BIN_PATH=$HOME/bin
FFMPEG_ENABLE="--enable-gpl --enable-nonfree"

[ ! -d "$SRC_PATH" ] && mkdir -pv "$SRC_PATH"
[ ! -d "$BUILD_PATH" ] && mkdir -pv "$BUILD_PATH"
[ ! -d "$BIN_PATH" ] && mkdir -pv "$BIN_PATH"

##
# libSDL2 nécessaire pour compiler ffplay
##
installLibSDL2() {
  echo "* installLibSDL2"
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
}

##
# activer ffplay
##
enableFfplay() {
  echo "* enableFfplay"
  installLibSDL2
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-ffplay"
}

##
# désactiver ffplay
##
disableFfplay() {
  echo "* disableFfplay"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --disable-ffplay"
}

##
# NASM : que pour liblame ??
##
installNASM() {
  cd "$SRC_PATH" || return
  if [ ! -d "nasm-2.14.02" ]; then
    echo "* téléchargement NASM"
    curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2
    tar xjvf nasm-2.14.02.tar.bz2
  fi
  cd nasm-2.14.02 || return
  echo "* compilation NASM"
  ./autogen.sh
  ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
  make && \
  make install
}

##
# Yasm
##
installYasm() {
  cd "$SRC_PATH" || return
  if [ ! -d "yasm-1.3.0" ]; then
    echo "* téléchargement Yasm"
    curl -O -L http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
    tar xzvf yasm-1.3.0.tar.gz
  fi
  echo "* compilation Yasm"
  cd yasm-1.3.0 && \
  ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
  make && \
  make install
}

##
# libx264
##
installLibX264() {
  cd "$SRC_PATH" || return
  if [ ! -d "x264" ]; then
    echo "* téléchargement x264"
    git clone --depth 1 https://code.videolan.org/videolan/x264.git
  fi
  echo "* compilation x264"
  cd x264 && \
  PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
  PATH="$BIN_PATH:$PATH" make && \
  make install
}

##
#
##
enableLibX264() {
  echo "* enableLibX264"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libx264"
}

##
# libx265
##
installLibX265() {
  echo "* installLibX265"
  cd "$SRC_PATH" || return
  if [ ! -d "x265" ]; then
    brew install mercurial x265
    hg clone https://bitbucket.org/multicoreware/x265
  fi
  cd x265/build/linux && \
  # prochaine ligne à changer ?
  PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
  PATH="$BIN_PATH:$PATH" make && \
  make install
}

##
#
##
enableLibX265() {
  echo "* enableLibX265"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libx265"
}

##
# fdk_aac
##
installLibFdkAac() {
  echo "* installLibFdkAac"
  cd "$SRC_PATH" || return
  if [ ! -d "fdk-aac" ]; then
    git clone --depth 1 https://github.com/mstorsjo/fdk-aac
  fi
  brew install libtool
  cd fdk-aac && \
  autoreconf -fiv && \
  ./configure --prefix="$BUILD_PATH" --disable-shared && \
  make && \
  make install
}

##
#
##
enableLibFdkAac() {
  echo "* enableLibFdkAac"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libfdk_aac"
}

##
#
##
enableLibNDINewTek() {
  echo "* enableLibNDINewTek"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libndi_newtek"
  # ajout --extra-cflags ?
  # ajout --extra-ldflags ?
}

##
# libass
##
installLibAss() {
  echo "* installLibAss"
  cd "$SRC_PATH" && \
  if [ ! -d "libass" ]; then
    git clone https://github.com/libass/libass.git
  fi
  cd libass && \
  ./autogen.sh && \
  PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
  PATH="$BIN_PATH:$PATH" make && \
  make install
}

##
#
##
enableLibAss() {
  echo "* enableLibAss"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libfreetype --enable-libass"
}

##
# ffmpeg
##
installFfmpeg() {
  cd "$SRC_PATH" || return
  if [ ! -d "ffmpeg-4.1.5" ]; then
    echo "* téléchargement ffmpeg"
    curl -O -L https://ffmpeg.org/releases/ffmpeg-4.1.5.tar.bz2 && \
    tar xjvf ffmpeg-4.1.5.tar.bz2
  fi
  echo "* compilation ffmpeg"
  cd ffmpeg-4.1.5 && \
  PATH="$BIN_PATH:$PATH" PKG_CONFIG_PATH="$BUILD_PATH/lib/pkgconfig" ./configure \
    --prefix="$BUILD_PATH" \
    --extra-cflags="-I$BUILD_PATH/include" \
    --extra-ldflags="-L$BUILD_PATH/lib" \
    --bindir="$BIN_PATH" \
    ${FFMPEG_ENABLE} && \
  PATH="$BIN_PATH:$PATH" make && \
  make install
}
#    --extra-cflags="-I$BUILD_PATH/include" \
#    --extra-ldflags="-L$BUILD_PATH/lib" \
#    --extra-cflags="-I$BUILD_PATH/include -I/Library/NDI\ SDK\ for\ Apple/include" \
#    --extra-ldflags="-L$BUILD_PATH/lib -L/Library/NDI\ SDK\ for\ Apple/lib/x64" \

if ! command -v "brew" > /dev/null; then
  echo "homebrew non installé"
  exit 1
fi

echo "DEBUT compilation FFMPEG"

echo "calcul dépendances de compilation"

# divers outils de compilation
brew install automake pkg-config

##
# à adapter (commenter/décommenter) suivant les besoins
##

installNASM
installYasm

installLibX264
#installLibX265
#installLibFdkAac
installLibAss

enableLibX264
#enableLibX265
#enableLibFdkAac
enableLibNDINewTek
enableLibAss

#disableFfplay
enableFfplay

installFfmpeg

echo "FIN compilation FFMPEG"
