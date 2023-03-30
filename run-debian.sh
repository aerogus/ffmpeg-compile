#!/usr/bin/env bash

##
# Compilation Debian de ffmpeg static avec modules additionnels
#
# Modules supportés :
# - libfdk_aac (Fraunhofer FDK AAC)
# - libmp3lame
# - libass (sous-titrage)
# - libx264
# - libx265
# - libfreetype (pour drawtext)
# - libfontconfig (fallback font par défaut)
##

ENABLE_X264=0
ENABLE_X265=0
ENABLE_FDKAAC=0
ENABLE_ASS=0
ENABLE_MP3LAME=0
ENABLE_FFPLAY=0

VERSION_NASM="2.16.01"  # check 2023-03-29
VERSION_YASM="1.3.0"    # check 2023-03-29
VERSION_MP3LAME="3.100" # check 2023-03-29
VERSION_FFMPEG="5.1.3"  # check 2023-03-29
VERSION_X264="stable"
VERSION_FDKAAC="master"

if [[ ! -f "/etc/debian_version" ]]; then
  echo "Ce script tourne uniquement sous Debian"
  exit 1
fi

ABS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRC_PATH="${ABS_PATH}/src"
BUILD_PATH="${ABS_PATH}/build"
BIN_PATH="${ABS_PATH}/bin"
CPU_COUNT=$(nproc)
FFMPEG_ENABLE="--enable-gpl --enable-nonfree"

[[ ! -d "$SRC_PATH" ]] && mkdir -pv "$SRC_PATH"
[[ ! -d "$BUILD_PATH" ]] && mkdir -pv "$BUILD_PATH"
[[ ! -d "$BIN_PATH" ]] && mkdir -pv "$BIN_PATH"

##
# activer ffplay
##
enableFfplay() {
  echo "* enableFfplay"
  apt-get -y install libsdl2-dev libva-dev libvdpau-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev
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
  echo "* install NASM $VERSION_NASM"
  cd "$SRC_PATH" || return

  if [[ ! -d "nasm-$VERSION_NASM" ]]; then
    echo "  - Téléchargement NASM"
    curl -O -L "https://www.nasm.us/pub/nasm/releasebuilds/${VERSION_NASM}/nasm-${VERSION_NASM}.tar.bz2"
    tar xjvf "nasm-${VERSION_NASM}.tar.bz2"
  else
    echo "  - NASM déjà téléchargé"
  fi

  if [[ ! -f "${BIN_PATH}/nasm" ]]; then
    echo "  - Compilation NASM"
    cd nasm-$VERSION_NASM && \
    ./autogen.sh && \
    ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
    make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - NASM déjà compilé"
  fi
}

##
# Yasm
##
installYasm() {
  echo "* install Yasm"
  cd "$SRC_PATH" || return

  if [[ ! -d "yasm-$VERSION_YASM" ]]; then
    echo "  - Téléchargement Yasm"
    curl -O -L "http://www.tortall.net/projects/yasm/releases/yasm-$VERSION_YASM.tar.gz" && \
    tar xzvf "yasm-$VERSION_YASM.tar.gz" && \
    rm "yasm-$VERSION_YASM.tar.gz"
  else
    echo "  - Yasm déjà téléchargé"
  fi

  if [[ ! -f "${BIN_PATH}/yasm" ]]; then
    echo "  - Compilation Yasm"
    cd yasm-$VERSION_YASM && \
    PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
    make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - Yasm déjà compilé"
  fi
}

##
# libx264
##
installLibX264() {
  echo "* installLibX264"

  # version déjà packagée par Debian : marche pas
  #apt-get install -y libx264-dev
  #return

  # ou à partir des sources
  cd "$SRC_PATH" || return

  if [[ ! -d "x264" ]]; then
    echo "  - Téléchargement x264"
    git clone --depth 1 --branch "$VERSION_X264" https://code.videolan.org/videolan/x264.git
  else
    echo "  - x264 déjà téléchargé"
  fi

  if [[ ! -f "${BIN_PATH}/x264" ]]; then
    echo "  - Compilation x264"
    cd x264 && \
    PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
    PATH="$BIN_PATH:$PATH" make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - x264 déjà compilé"
  fi
}

##
#
##
enableLibX264() {
  echo "* enableLibX264"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libx264"
}

##
#
##
installLibX265() {
  echo "* installLibX265"
  apt-get install -y libx265-dev libnuma-dev
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

  if [[ ! -d "fdk-aac" ]]; then
    echo "  - Téléchargement fdk-aac"
    git clone --depth 1 --branch "$VERSION_FDKAAC" https://github.com/mstorsjo/fdk-aac
  else
    echo "  - fdk-aac déjà téléchargé"
  fi

  if [[ ! -f "${BUILD_PATH}/lib/libfdk-aac.a" ]] || [[ ! -f "${BUILD_PATH}/lib/libfdk-aac.la" ]]; then
    echo "  - Compilation fdk-aac"
    cd fdk-aac && \
    autoreconf -fiv && \
    ./configure --prefix="$BUILD_PATH" --disable-shared && \
    make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - fdk-aac déjà compilé"
  fi
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

  if [[ ! -d "lame-$VERSION_MP3LAME" ]]; then
    echo "  - Téléchargement lame"
    curl -O -L "https://downloads.sourceforge.net/project/lame/lame/$VERSION_MP3LAME/lame-$VERSION_MP3LAME.tar.gz"
    tar xzvf "lame-$VERSION_MP3LAME.tar.gz"
  else
    echo "  - lame déjà téléchargé"
  fi

  if [[ ! -f "${BUILD_PATH}/lib/libmp3lame.a" ]] || [[ ! -f "${BUILD_PATH}/lib/libmp3lame.la" ]]; then
    echo "  - Compilation lame"
    cd "lame-$VERSION_MP3LAME" && \
    PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --disable-shared --enable-nasm && \
    PATH="$BIN_PATH:$PATH" make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - lame déjà compilé"
  fi
}

enableLibMp3Lame() {
  echo "* enableLibMp3Lame"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libmp3lame"
}

##
#
##
installLibAss() {
  echo "* installLibAss"
}

##
#
##
enableLibAss() {
  echo "* enableLibAss"
}

##
# ffmpeg
##
installFfmpeg() {
  echo "* installFfmpeg $VERSION_FFMPEG"
  cd "$SRC_PATH" || return

  if [[ ! -d "ffmpeg-$VERSION_FFMPEG" ]]; then
    echo "  - Téléchargement ffmpeg"
    curl -O -L "https://ffmpeg.org/releases/ffmpeg-$VERSION_FFMPEG.tar.bz2" && \
    tar xjvf "ffmpeg-$VERSION_FFMPEG.tar.bz2" && \
    rm "ffmpeg-$VERSION_FFMPEG.tar.bz2"
  else
    echo "  - ffmpeg déjà téléchargé"
  fi

  if true; then
    echo "  - Compilation ffmpeg"
    cd ffmpeg-$VERSION_FFMPEG && \
    PATH="$BIN_PATH:$PATH" PKG_CONFIG_PATH="$BUILD_PATH/lib/pkgconfig" ./configure \
      --prefix="$BUILD_PATH" \
      --pkg-config-flags="--static" \
      --extra-cflags="-I$BUILD_PATH/include" \
      --extra-ldflags="-L$BUILD_PATH/lib" \
      --extra-libs="-lpthread -lm" \
      --bindir="$BIN_PATH" \
      $FFMPEG_ENABLE && \
    PATH="$BIN_PATH:$PATH" make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - ffmpeg déjà compilé"
  fi
}

echo "- Mise à jour globale Debian"
apt -y update
apt -y full-upgrade

##
# diverses dépendances
##

echo "- Installation dépendances générales"
apt-get install -y curl bzip2 autoconf automake g++ cmake libtool pkg-config git-core

#  ajout ?
#  build-essential \
#  libass-dev \
#  libfreetype6-dev \
#  libvorbis-dev \
#  zlib1g-dev

echo "DEBUT compilation FFMPEG"

installNASM
installYasm

if [[ $ENABLE_X264 -eq 1 ]]; then
  installLibX264
  enableLibX264
fi

if [[ $ENABLE_X265 -eq 1 ]]; then
  installLibX265
  enableLibX265
fi

if [[ $ENABLE_FDKAAC -eq 1 ]]; then
  installLibFdkAac
  enableLibFdkAac
fi

if [[ $ENABLE_ASS -eq 1 ]]; then
  installLibAss
  enableLibAss
fi

if [[ $ENABLE_MP3LAME -eq 1 ]]; then
  installLibMp3Lame
  enableLibMp3Lame
fi

if [[ $ENABLE_FFPLAY -eq 1 ]]; then
  enableFfplay
else
  disableFfplay
fi

installFfmpeg

echo "FIN compilation FFMPEG"
