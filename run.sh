#!/usr/bin/env bash

##
# Compilation multiplateformes de ffmpeg static avec modules additionnels
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

if [[ -f "/etc/redhat-release" ]]; then
  OS="centos"
elif [[ -f "/etc/debian_version" ]]; then
  OS="debian"
else
  # brew install xxx ?
  OS="macos"
fi

ABS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRC_PATH="${ABS_PATH}/src"
BUILD_PATH="${ABS_PATH}/build"
BIN_PATH="${ABS_PATH}/bin"
CPU_COUNT=$(nproc)
FFMPEG_ENABLE="--enable-gpl --enable-nonfree"

# chargement de la conf
. "$ABS_PATH/conf.ini.sh"

[[ ! -d "$SRC_PATH" ]] && mkdir -pv "$SRC_PATH"
[[ ! -d "$BUILD_PATH" ]] && mkdir -pv "$BUILD_PATH"
[[ ! -d "$BIN_PATH" ]] && mkdir -pv "$BIN_PATH"

### WIP ###
### A IMPORTER / ADAPTER des scripts run-centos.sh + run-debian.sh + run-macos.sh ###
### WIP ###

echo "DEBUT compilation FFMPEG"

echo "- Installation dépendances générales"
###

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
