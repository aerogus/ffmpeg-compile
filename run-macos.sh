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

VERSION_SDL2="2.0.14"
VERSION_NASM="2.15.05"
VERSION_YASM="1.3.0"
VERSION_LAME="3.100"
VERSION_FFMPEG="4.3.2"

[ ! -d "$SRC_PATH" ] && mkdir -pv "$SRC_PATH"
[ ! -d "$BUILD_PATH" ] && mkdir -pv "$BUILD_PATH"
[ ! -d "$BIN_PATH" ] && mkdir -pv "$BIN_PATH"

##
# libSDL2 nécessaire pour compiler ffplay
##
installLibSDL2() {
  echo "* installLibSDL2 $VERSION_SDL2"
  cd "$SRC_PATH" || return
  if [ ! -d "SDL2-$VERSION_SDL2" ]; then
    curl -O -L http://www.libsdl.org/release/SDL2-$VERSION_SDL2.tar.gz && \
    tar fvxz SDL2-$VERSION_SDL2.tar.gz && \
    rm tar fvxz SDL2-$VERSION_SDL2.tar.gz
  fi
  cd SDL2-$VERSION_SDL2 && \
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
  if [ ! -d "nasm-$VERSION_NASM" ]; then
    echo "* téléchargement NASM $VERSION_NASM"
    curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/$VERSION_NASM/nasm-$VERSION_NASM.tar.bz2
    tar xjvf nasm-$VERSION_NASM.tar.bz2
  fi
  cd nasm-$VERSION_NASM || return
  echo "* compilation NASM $VERSION_NASM"
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
  if [ ! -d "yasm-$VERSION_YASM" ]; then
    echo "* téléchargement Yasm $VERSION_YASM"
    curl -O -L http://www.tortall.net/projects/yasm/releases/yasm-$VERSION_YASM.tar.gz
    tar xzvf yasm-$VERSION_YASM.tar.gz
  fi
  echo "* compilation Yasm $VERSION_YASM"
  cd yasm-$VERSION_YASM && \
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

installLibMp3Lame() {
  echo "* installLibMp3Lame"
  cd "$SRC_PATH" || return
  if [ ! -d "lame-$VERSION_LAME" ]; then
    echo "* téléchargement lame"
    curl -O -L https://downloads.sourceforge.net/project/lame/lame/$VERSION_LAME/lame-$VERSION_LAME.tar.gz
    tar xzvf lame-$VERSION_LAME.tar.gz
  fi
  echo "* compilation lame"
  cd lame-$VERSION_LAME && \
  PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --disable-shared --enable-nasm && \
  PATH="$BIN_PATH:$PATH" make && \
  make install
}

enableLibMp3Lame() {
  echo "* enableLibMp3Lame"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libmp3lame"
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
  if [ ! -d "ffmpeg-$VERSION_FFMPEG" ]; then
    echo "* téléchargement ffmpeg $VERSION_FFMPEG"
    curl -O -L https://ffmpeg.org/releases/ffmpeg-$VERSION_FFMPEG.tar.bz2 && \
    tar xjvf ffmpeg-$VERSION_FFMPEG.tar.bz2
  fi
  echo "* compilation ffmpeg $VERSION_FFMPEG"
  cd ffmpeg-$VERSION_FFMPEG && \
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

echo "DEBUT compilation FFMPEG $VERSION_FFMPEG"

echo "calcul dépendances de compilation"

# divers outils de compilation
brew install automake pkg-config

##
# à adapter (commenter/décommenter) suivant les besoins
##

installNASM
installYasm

installLibX264
installLibX265
installLibFdkAac
installLibAss
installLibMp3Lame

enableLibX264
enableLibX265
#enableLibFdkAac
#enableLibNDINewTek
enableLibAss
enableLibMp3Lame

#disableFfplay
enableFfplay

installFfmpeg

echo "FIN compilation FFMPEG"
