#!/usr/bin/env bash

##
# Compilation MacOS de ffmpeg static avec modules additionnels
#
# Modules supportés :
# - libfdk_aac (Fraunhofer FDK AAC)
# - libass (sous-titrage)
# - libx264
# - libx265
# - libfreetype (pour drawtext)
# - libfontconfig (fallback font par défaut)
##

# installation locale
SRC_PATH="${HOME}/ffmpeg_sources"
BUILD_PATH="${HOME}/ffmpeg_build"
BIN_PATH="${HOME}/bin"
FFMPEG_ENABLE="--enable-gpl --enable-nonfree"

VERSION_SDL2="2.24.0"   # check 2022-10-03
VERSION_NASM="2.15.05"  # check 2022-10-03
VERSION_YASM="1.3.0"    # check 2022-10-03
VERSION_MP3LAME="3.100" # check 2022-10-03
VERSION_FFMPEG="5.1.2"  # check 2022-10-03

ENABLE_X264=1
ENABLE_X265=1
ENABLE_FDKAAC=1
ENABLE_ASS=0
ENABLE_MP3LAME=1
ENABLE_FFPLAY=0

[[ ! -d "$SRC_PATH" ]] && mkdir -pv "$SRC_PATH"
[[ ! -d "$BUILD_PATH" ]] && mkdir -pv "$BUILD_PATH"
[[ ! -d "$BIN_PATH" ]] && mkdir -pv "$BIN_PATH"

##
# libSDL2 nécessaire pour compiler ffplay
##
installLibSDL2() {
  echo "* installLibSDL2 $VERSION_SDL2"
  cd "$SRC_PATH" || return

  if [[ ! -d "SDL2-$VERSION_SDL2" ]]; then
    echo "  - Téléchargement libSDL2"
    curl -O -L "http://www.libsdl.org/release/SDL2-${VERSION_SDL2}.tar.gz" && \
    tar fvxz "SDL2-${VERSION_SDL2}.tar.gz" && \
    rm tar fvxz "SDL2-${VERSION_SDL2}.tar.gz"
  else
    echo "  - libSDL2 déjà téléchargé"
  fi

  if true; then
    echo "  - Compilation libSDL2"
    cd SDL2-$VERSION_SDL2 && \
    PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
    make && \
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
##
installNASM() {
  echo "* installation NASM ${VERSION_NASM}"
  cd "$SRC_PATH" || return

  if [[ ! -d "nasm-$VERSION_NASM" ]]; then
    echo "  - Téléchargement NASM $VERSION_NASM"
    curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/$VERSION_NASM/nasm-$VERSION_NASM.tar.bz2
    tar xjvf nasm-$VERSION_NASM.tar.bz2
  else
    echo "  - NASM déjà téléchargé"
  fi

  if true; then
    echo "  - Compilation NASM $VERSION_NASM"
    cd nasm-$VERSION_NASM || return
    ./autogen.sh
    ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
    make && \
    make install
  else
    echo "  - NASM déjà compilé"
  fi
}

##
# Yasm
##
installYasm() {
  echo "* Installation Yasm $VERSION_YASM"
  cd "$SRC_PATH" || return

  if [[ ! -d "yasm-$VERSION_YASM" ]]; then
    echo "  - Téléchargement Yasm $VERSION_YASM"
    curl -O -L http://www.tortall.net/projects/yasm/releases/yasm-$VERSION_YASM.tar.gz
    tar xzvf yasm-$VERSION_YASM.tar.gz
  else
    echo "  - Yasm déjà téléchargé"
  fi

  if true; then
    echo "  - Compilation Yasm $VERSION_YASM"
    cd yasm-$VERSION_YASM && \
    ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
    make && \
    make install
  else
    echo "  - Yasm déjà compilé"
  fi
}

##
# libx264
##
installLibX264() {
  echo "* Installation x264"
  cd "$SRC_PATH" || return

  if [[ ! -d "x264" ]]; then
    echo "  - Téléchargement x264"
    git clone --depth 1 https://code.videolan.org/videolan/x264.git
  else
    echo "  - x264 déjà téléchargé"
  fi

  if true; then
    echo "  - Compilation x264"
    cd x264 && \
    PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
    PATH="$BIN_PATH:$PATH" make && \
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
# libx265
##
installLibX265() {
  echo "* installLibX265"
  cd "$SRC_PATH" || return

  if [[ ! -d "x265" ]]; then
    echo "  - Téléchargement x265"
    brew install x265
    git clone https://github.com/videolan/x265
  else
    echo "  - x265 déjà téléchargé"
  fi

  if true; then
    echo "  - Compilation x265"
    cd x265/build/linux && \
    # prochaine ligne à changer ?
    PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
    PATH="$BIN_PATH:$PATH" make && \
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

  if true; then
    echo "  - Compilation fdk-aac"
    brew install libtool
    cd fdk-aac && \
    autoreconf -fiv && \
    ./configure --prefix="$BUILD_PATH" --disable-shared && \
    make && \
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

  if true; then
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
# libass
##
installLibAss() {
  echo "* Installation libAss"
  cd "$SRC_PATH" || return

  if [[ ! -d "libass" ]]; then
    echo "  - Téléchargement libass"
    git clone https://github.com/libass/libass.git
  else
    echo "  - libass déjà téléchargé"
  fi

  if true; then
    echo "  - Compilation libass"
    cd libass && \
    ./autogen.sh && \
    PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
    PATH="$BIN_PATH:$PATH" make && \
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
  FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libfreetype --enable-libass"
}

##
# ffmpeg
##
installFfmpeg() {
  echo "* installation ffmpeg"
  cd "$SRC_PATH" || return

  if [[ ! -d "ffmpeg-$VERSION_FFMPEG" ]]; then
    echo "  - Téléchargement ffmpeg $VERSION_FFMPEG"
    curl -O -L https://ffmpeg.org/releases/ffmpeg-$VERSION_FFMPEG.tar.bz2 && \
    tar xjvf ffmpeg-$VERSION_FFMPEG.tar.bz2
  else
    echo "  - ffmpeg déjà téléchargé"
  fi

  if true; then
    echo "  - Compilation ffmpeg $VERSION_FFMPEG"
    cd "ffmpeg-$VERSION_FFMPEG" && \
    PATH="$BIN_PATH:$PATH" PKG_CONFIG_PATH="$BUILD_PATH/lib/pkgconfig" ./configure \
      --prefix="$BUILD_PATH" \
      --extra-cflags="-I$BUILD_PATH/include" \
      --extra-ldflags="-L$BUILD_PATH/lib" \
      --bindir="$BIN_PATH" \
      $FFMPEG_ENABLE && \
    PATH="$BIN_PATH:$PATH" make && \
    make install
  else
    echo "  - ffmpeg déjà compilé"
  fi
}

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
