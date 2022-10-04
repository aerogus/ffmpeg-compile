#!/usr/bin/env bash

##
# Compilation CentOS de ffmpeg static avec modules additionnels
#
# Modules supportés :
# - libfdk_aac (Fraunhofer FDK AAC)
# - libass (sous-titrage)
# - libx264
# - libx265
# - libfreetype (pour drawtext)
# - libfontconfig (fallback font par défaut)
##

if [[ ! -f "/etc/redhat-release" ]]; then
  echo "Ce script tourne uniquement sous CentOS"
  exit 1
fi

SRC_PATH="${HOME}/centos/ffmpeg_sources"
BUILD_PATH="${HOME}/centos/ffmpeg_build"
BIN_PATH="${HOME}/centos/bin"
CPU_COUNT=$(nproc)
FFMPEG_ENABLE="--enable-gpl --enable-nonfree"

VERSION_FRIBIDI="1.0.12" # check 2022-10-03
VERSION_SDL2="2.24.0"    # check 2022-10-03
VERSION_NASM="2.15.05"   # check 2022-10-03
VERSION_YASM="1.3.0"     # check 2022-10-03
VERSION_MP3LAME="3.100"  # check 2022-10-03
VERSION_FFMPEG="5.1.2"   # check 2022-10-03

ENABLE_X264=1
ENABLE_X265=1
ENABLE_FDKAAC=1
ENABLE_ASS=1
ENABLE_MP3LAME=1
ENABLE_FFPLAY=0

[[ ! -d "$SRC_PATH" ]] && mkdir -pv "$SRC_PATH"
[[ ! -d "$BUILD_PATH" ]] && mkdir -pv "$BUILD_PATH"
[[ ! -d "$BIN_PATH" ]] && mkdir -pv "$BIN_PATH"

# Téléchargement et décompression de toutes les dépendances externes
# à jour au 01/06/2019

##
# libSDL2 nécessaire pour compiler ffplay
# note: pas dispo dans base ni epel
##
installLibSDL2() {
  echo "* installLibSDL2 ${VERSION_SDL2}"
  cd "$SRC_PATH" || return
  if [[ ! -d "SDL2-${VERSION_SDL2}" ]]; then
    echo "  - Téléchargement libSDL2"
    curl -O -L "http://www.libsdl.org/release/SDL2-${VERSION_SDL2}.tar.gz" && \
    tar fvxz "SDL2-${VERSION_SDL2}.tar.gz" && \
    rm tar fvxz "SDL2-${VERSION_SDL2}.tar.gz"
  else
    echo "  - libSDL2 déjà téléchargé"
  fi
  if true; then
    echo "  - Compilation libSDL2"
    cd "SDL2-${VERSION_SDL2}" && \
    PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
    make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - libSDL2 déjà compilé"
  fi
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
# note: compilation indispensable car CentOS 7 est fourni avec NASM 2.10 et ffmpeg requiert >= 2.13
##
installNASM() {
  echo "* installation NASM ${VERSION_NASM}"
  cd "$SRC_PATH" || return

  if [[ ! -d "nasm-${VERSION_NASM}" ]]; then
    echo "  - Téléchargement NASM"
    curl -O -L "https://www.nasm.us/pub/nasm/releasebuilds/${VERSION_NASM}/nasm-${VERSION_NASM}.tar.bz2" && \
    tar xjvf "nasm-${VERSION_NASM}.tar.bz2" && \
    rm "nasm-${VERSION_NASM}.tar.bz2"
  else
    echo "  - NASM déjà téléchargé"
  fi

  if [[ ! -f "${BIN_PATH}/nasm" ]]; then
    echo "  - Compilation NASM vers $BIN_PATH"
    cd nasm-$VERSION_NASM && \
    ./autogen.sh && \
    PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
    make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - NASM déjà compilé"
  fi

}

##
# Yasm
# note: version 1.2.0-4.el7 dans epel (= minimum requis par ffmpeg)
##
installYasm() {
  echo "* install Yasm $VERSION_YASM"
  cd "$SRC_PATH" || return

  if [[ ! -d "yasm-$VERSION_YASM" ]]; then
    echo "  - Téléchargement YASM"
    curl -O -L "http://www.tortall.net/projects/yasm/releases/yasm-$VERSION_YASM.tar.gz" && \
    tar xzvf "yasm-$VERSION_YASM.tar.gz" && \
    rm "yasm-$VERSION_YASM.tar.gz"
  else
    echo "  - YASM déjà téléchargé"
  fi

  if [[ ! -f "${BIN_PATH}/yasm" ]]; then
    echo "  - Compilation YASM vers $BIN_PATH"
    cd yasm-$VERSION_YASM && \
    PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
    make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - YASM déjà compilé"
  fi

}

##
# libx264
# note: pas dispo dans base ni epel
##
installLibX264() {
  echo "* installLibX264"
  cd "$SRC_PATH" || return

  if [[ ! -d "x264" ]]; then
    echo "  - Téléchargement x264"
    git clone --depth 1 https://code.videolan.org/videolan/x264.git
  else
    echo "  - x264 déjà téléchargé"
  fi

  if [[ ! -f "${BIN_PATH}/x264" ]]; then
    echo "  - Compilation x264"
    cd x264 && \
    PATH="$BIN_PATH:$PATH" PKG_CONFIG_PATH="$BUILD_PATH/lib/pkgconfig" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static
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
  cd "$SRC_PATH" || return

  if [[ ! -d "x265" ]]; then
    echo "  - Téléchargement x265"
    git clone https://github.com/videolan/x265
  else
    echo "  - x265 déjà téléchargé"
  fi

  if [[ ! -f "${BIN_PATH}/x265" ]]; then
    echo "  - Compilation x265"
    cd x265/build/linux && \
    PATH="$BIN_PATH:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$BUILD_PATH" -DENABLE_SHARED:bool=off ../../source && \
    PATH="$BIN_PATH:$PATH" make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - x265 déjà compilé"
  fi
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
# note: pas dispo dans base ni epel
##
installLibFdkAac() {
  echo "* installLibFdkAac"
  cd "$SRC_PATH" || return

  if [[ ! -d "fdk-aac" ]]; then
    echo "  - Téléchargement fdk-aac"
    git clone --depth 1 https://github.com/mstorsjo/fdk-aac
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
    PATH="$BIN_PATH:$PATH" make && \
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
# fribidi nécessaire à libass
# note: version 1.0.2-1.el7 dans base
##
installFribidi() {
  echo "* installFribidi $VERSION_FRIBIDI"
  cd "$SRC_PATH" || return
  if [[ ! -d "fribidi-$VERSION_FRIBIDI" ]]; then
    echo "  - Téléchargemeng Fribidi"
    curl -L "https://github.com/fribidi/fribidi/archive/refs/tags/v${VERSION_FRIBIDI}.tar.gz" -o "fribidi-${VERSION_FRIBIDI}.tar.gz"
    tar xzvf "fribidi-${VERSION_FRIBIDI}.tar.gz" && \
    rm "fribidi-${VERSION_FRIBIDI}.tar.gz"
  else
    echo "  - Fribidi déjà téléchargé"
  fi

  if true; then
    echo "  - Compilation Fribidi"
    echo "fribidi-${VERSION_FRIBIDI}"
    cd "fribidi-${VERSION_FRIBIDI}" && ./autogen.sh && \
    PATH="$BIN_PATH:$PATH" ./configure --prefix="${BUILD_PATH}" --bindir="${BIN_PATH}" --disable-shared --enable-static && \
    make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - Fribidi déjà compilé"
  fi
}

##
# libass
# options possibles: --disable-fontconfig, --disable-static
# note: dans epel, version 0.13.4-6.el7
##
installLibAss() {
  echo "* installLibAss"

  installFribidi

  cd "$SRC_PATH" || return
  if [[ ! -d "libass" ]]; then
    echo "  - Téléchargement libass"
    git clone https://github.com/libass/libass.git
  else
    echo "  - libass déjà téléchargé"
  fi

  if true; then
    echo "  - Compilation libass"
    yum -y install harfbuzz-devel
    cd libass && \
    ./autogen.sh && \
    PATH="$BIN_PATH:$PATH" PKG_CONFIG_PATH="$BUILD_PATH/lib/pkgconfig" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --disable-shared --enable-static --disable-require-system-font-provider && \
    PATH="$BIN_PATH:$PATH" make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - libass déjà compilé"
  fi
}

##
#
##
enableLibAss() {
  echo "* enableLibAss"
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libfribidi --enable-libfreetype --enable-libass"
}

##
# ffmpeg
# note: pas dispo dans base ni epel
##
installFfmpeg() {
  echo "* installFfmpeg $VERSION_FFMPEG"
  cd "$SRC_PATH" || return
  if [[ ! -d "ffmpeg-$VERSION_FFMPEG" ]]; then
    echo "  - Téléchargement ffmpeg"
    curl -O -L "https://ffmpeg.org/releases/ffmpeg-${VERSION_FFMPEG}.tar.bz2" && \
    tar xjvf "ffmpeg-${VERSION_FFMPEG}.tar.bz2" && \
    rm "ffmpeg-${VERSION_FFMPEG}.tar.bz2"
  else
    echo "  - ffmpeg déjà téléchargé"
  fi

  if true; then
    echo "  - Compilation ffmpeg"
    cd ffmpeg-$VERSION_FFMPEG && \
    PATH="$BIN_PATH:$PATH" PKG_CONFIG_PATH="$BUILD_PATH/lib/pkgconfig" ./configure \
      --prefix="$BUILD_PATH" \
      --pkg-config-flags=--static \
      --extra-cflags="-I$BUILD_PATH/include" \
      --extra-ldflags="-L$BUILD_PATH/lib" \
      --extra-libs=-lpthread \
      --extra-libs=-lm \
      --bindir="$BIN_PATH" \
      $FFMPEG_ENABLE && \
    PATH="$BIN_PATH:$PATH" make -j "${CPU_COUNT}" && \
    make install
  else
    echo "  - ffmpeg déjà compilé"
  fi
}

##
# à adapter (commenter/décommenter) suivant les besoins
##

echo "DEBUT compilation FFMPEG"

# Dépendances générales"
# file pour ? optionnel ?
# which pour autogen.sh de fribidi
# bzip2 pour décompresser les archives .tar.bz2
yum -y install autoconf automake bzip2 bzip2-devel cmake freetype-devel gcc gcc-c++ git libtool make pkgconfig zlib-devel file which

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
