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
# - libflite (WIP) (text 2 speech) darwin only
##

ABS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "DEBUT"

# shellcheck disable=SC1091
. "$ABS_PATH/conf.ini.sh"

# shellcheck disable=SC1091
. "$ABS_PATH/functions.sh"

OS=$(detectOs)
if [[ ! "$OS" ]]; then
    echo "OS inconnu / non supporté"
    exit 1
fi

CPU_COUNT=$(cpuCount)
if [[ ! "$CPU_COUNT" ]]; then
    echo "Nombre de CPU inconnu"
    exit 1
fi

export SRC_PATH="$ABS_PATH/src/$OS"
export BUILD_PATH="$ABS_PATH/build/$OS"
export BIN_PATH="$ABS_PATH/bin/$OS"

export FFMPEG_ENABLE="--enable-gpl --enable-nonfree"

echo "- Création des répertoires de travail"
mkBaseDirs

#echo "- Mise à jour globale du système"
#systemUpdate

echo "- Installation des dépendances générales"
installDependencies

echo "- Installation des assembleurs"
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

if [[ $ENABLE_OPUS -eq 1 ]]; then
  installLibOpus
  enableLibOpus
fi

if [[ $ENABLE_OPENSSL -eq 1 ]]; then
  enableOpenssl
fi

if [[ $ENABLE_ZIMG -eq 1 ]]; then
  enableZimg
fi

# @see http://johnriselvato.com/how-to-install-flite-flitevox-for-ffmpeg/
if [[ $ENABLE_FLITE -eq 1 ]] && [[ $OS == "darwin" ]]; then
  installFlite
  enableLibFlite
fi

if [[ $ENABLE_FFPLAY -eq 1 ]]; then
  enableFfplay
else
  disableFfplay
fi

installFfmpeg

echo "FIN"
