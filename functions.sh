#!/usr/bin/env bash

detectOs()
{
    local OS_DETECT

    if [[ -f "/etc/redhat-release" ]]; then
        OS_DETECT="redhat"
    elif [[ -f "/etc/debian_version" ]]; then
        OS_DETECT="debian"
    elif [[ $(uname) == "Darwin" ]]; then
        OS_DETECT="darwin"
    fi

    echo "$OS_DETECT"
}

cpuCount()
{
    local CPU_DETECT

    if [[ "$OS" == "redhat" ]] || [[ "$OS" == "debian" ]]; then
        CPU_DETECT=$(nproc)
    elif [[ "$OS" == "darwin" ]]; then
        CPU_DETECT=$(sysctl -n hw.logicalcpu)
    else
        CPU_DETECT=-1
    fi

    echo "$CPU_DETECT"
}

mkBaseDirs()
{
    if [[ ! -d "$SRC_PATH" ]]; then
        mkdir -pv "$SRC_PATH"
    fi

    if [[ ! -d "$BUILD_PATH" ]]; then
        mkdir -pv "$BUILD_PATH"
    fi

    if [[ ! -d "$BIN_PATH" ]]; then
        mkdir -pv "$BIN_PATH"
    fi
}

##
# mise à jour globale du système
##
systemUpdate()
{
    if [[ "$OS" == "debian" ]]; then
        apt -y update
        apt -y full-upgrade
    elif [[ "$OS" == "redhat" ]]; then
        yum -y update
        yum -y upgrade
    elif [[ "$OS" == "darwin" ]]; then
        brew update
        brew upgrade
    fi
}

##
# Installation des dépendances globales
##
installDependencies()
{
    if [[ "$OS" == "debian" ]]; then
        apt -y install curl bzip2 autoconf automake g++ cmake libtool pkg-config git-core
    elif [[ "$OS" == "redhat" ]]; then
        # file pour ? optionnel ?
        # bzip2 pour décompresser les archives .tar.bz2
        yum -y install autoconf automake bzip2 bzip2-devel cmake gcc gcc-c++ git libtool make pkgconfig zlib-devel file
    elif [[ "$OS" == "darwin" ]]; then
        brew install automake pkg-config
    fi
}

##
# NASM : que utile pour liblame ?
#
# Note CentOS7: compilation indispensable car CentOS 7 est fourni avec NASM 2.10 et ffmpeg requiert >= 2.13
##
installNASM()
{
    echo "  - installation NASM $VERSION_NASM"
    cd "$SRC_PATH" || return

    if [[ ! -d "nasm-$VERSION_NASM" ]]; then
        echo "    - Téléchargement NASM $VERSION_NASM"
        curl -O -L "https://www.nasm.us/pub/nasm/releasebuilds/$VERSION_NASM/nasm-$VERSION_NASM.tar.bz2"
        tar xjvf "nasm-$VERSION_NASM.tar.bz2"
    else
        echo "    - NASM déjà téléchargé"
    fi

    if [[ ! -f "$BIN_PATH/nasm" ]]; then
        echo "    - Compilation NASM $VERSION_NASM"
        cd "nasm-$VERSION_NASM" && \
        ./autogen.sh && \
        ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
        make -j "${CPU_COUNT}" && \
        make install
    else
        echo "    - NASM déjà compilé"
    fi
}

##
# Yasm
#
# Note CentOS7: version 1.2.0-4.el7 dans epel (= minimum requis par ffmpeg)
##
installYasm()
{
    echo "  - Installation Yasm $VERSION_YASM"
    cd "$SRC_PATH" || return

    if [[ ! -d "yasm-$VERSION_YASM" ]]; then
        echo "    - Téléchargement Yasm $VERSION_YASM"
        curl -O -L "http://www.tortall.net/projects/yasm/releases/yasm-$VERSION_YASM.tar.gz"
        tar xzvf "yasm-$VERSION_YASM.tar.gz"
    else
        echo "    - Yasm déjà téléchargé"
    fi

    if [[ ! -f "$BIN_PATH/yasm" ]]; then
        echo "    - Compilation Yasm $VERSION_YASM"
        cd "yasm-$VERSION_YASM" && \
        PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" && \
        make -j "${CPU_COUNT}" && \
        make install
    else
        echo "    - Yasm déjà compilé"
    fi
}

##
# activer ffplay
##
enableFfplay()
{
    echo "  - enableFfplay"
    if [[ "$OS" == "debian" ]]; then
        apt -y install libsdl2-dev libva-dev libvdpau-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev
    else
        installLibSDL2
    fi
    FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-ffplay"
}

##
# désactiver ffplay
##
disableFfplay()
{
    echo "  - disableFfplay"
    FFMPEG_ENABLE="${FFMPEG_ENABLE} --disable-ffplay"
}

##
#
##
enableLibX264()
{
    echo "  - enableLibX264"
    FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libx264"
}

##
#
##
enableLibX265()
{
    echo "  - enableLibX265"
    FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libx265"
}

enableLibFdkAac()
{
    echo "  - enableLibFdkAac"
    FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libfdk_aac"
}

enableLibMp3Lame()
{
    echo "  - enableLibMp3Lame"
    FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libmp3lame"
}

enableLibOpus()
{
    echo "  - enableLibOpus"
    FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libopus"
}

enableLibFlite()
{
    echo "  - enableLibFlite"
    FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libflite"
}

enableLibAss()
{
    echo "  - enableLibAss"

    if [[ "$OS" == "redhat" ]]; then
        yum -y install freetype-devel
    fi
    if [[ "$OS" == "debian" ]]; then
        apt -y install libfreetype6-dev libfribidi-dev libharfbuzz-dev
    fi

    if [[ "$OS" == "redhat" ]]; then # pourquoi ?
        FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libfribidi --enable-libfreetype --enable-libass --enable-libharfbuzz --enable-libfontconfig"
    else 
        FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-libfreetype --enable-libass"
    fi
}

enableOpenssl()
{
    echo "  - enableOpenssl"
    if [[ "$OS" == "debian" ]]; then
        apt -y install libssl-dev
    elif [[ "$OS" == "redhat" ]]; then
        yum -y install libssl-dev
    fi
    FFMPEG_ENABLE="${FFMPEG_ENABLE} --enable-openssl"
}

##
# libSDL2 nécessaire pour compiler ffplay
#
# note CentOS7: pas dispo dans base ni epel
##
installLibSDL2()
{
    echo "  - installLibSDL2 $VERSION_SDL2"
    cd "$SRC_PATH" || return

    if [[ ! -d "SDL2-$VERSION_SDL2" ]]; then
        echo "  - Téléchargement libSDL2"
        curl -O -L "http://www.libsdl.org/release/SDL2-${VERSION_SDL2}.tar.gz" && \
        tar fvxz "SDL2-${VERSION_SDL2}.tar.gz" && \
        rm tar fvxz "SDL2-${VERSION_SDL2}.tar.gz"
    else
        echo "  - libSDL2 déjà téléchargé"
    fi

    if [[ ! -f "$BUILD_PATH/lib/libSDL2.a" ]]; then
        echo "  - Compilation libSDL2"
        cd SDL2-$VERSION_SDL2 && \
        PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
        make -j "${CPU_COUNT}" && \
        make install
    else
        echo "  - libSDL2 déjà compilé"
    fi
}

##
# libx264
# note CentOS7: pas dispo dans base ni epel
# note Debian: paquet ne marche pas
# note CentOS7: PKG_CONFIG_PATH="$BUILD_PATH/lib/pkgconfig"
##
installLibX264()
{
    echo "  - installLibX264 $VERSION_X264"
    cd "$SRC_PATH" || return

    # version déjà packagée par Debian : marche pas
    #apt -y install libx264-dev
    #return

    if [[ ! -d "x264" ]]; then
        echo "  - Téléchargement x264"
        git clone --depth 1 --branch "$VERSION_X264" https://code.videolan.org/videolan/x264.git
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
installLibX265()
{
    echo "  - installLibX265 $VERSION_X265"
    cd "$SRC_PATH" || return

    if [[ "$OS" == "darwin" ]]; then
        brew install x265
        return
    elif [[ "$OS" == "debian" ]]; then
        apt -y install libx265-dev libnuma-dev
        return
    elif [[ "$OS" == "redhat" ]]; then
        if [[ ! -d "x265" ]]; then
            echo "  - Téléchargement x265"
            git clone --depth 1 --branch "$VERSION_X265" https://github.com/videolan/x265
        else
            echo "  - x265 déjà téléchargé"
        fi

        if [[ ! -f "${BUILD_PATH}/bin/x265" ]]; then
            echo "  - Compilation x265"
            cd x265/build/linux && \
            PATH="$BIN_PATH:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$BUILD_PATH" -DENABLE_SHARED:bool=off ../../source && \
            PATH="$BIN_PATH:$PATH" make -j "${CPU_COUNT}" && \
            make install
        else
            echo "  - x265 déjà compilé"
        fi
    fi
}

##
# fdk_aac
#
##
installLibFdkAac()
{
    echo "  - installLibFdkAac $VERSION_FDKAAC"
    cd "$SRC_PATH" || return

    if [[ "$OS" == "darwin" ]]; then
        brew install libtool
    fi

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
# libass
# options possibles: --disable-fontconfig, --disable-static
# note CentOS7: dans epel, version 0.13.4-6.el7
##
installLibAss()
{
    echo "  - installLibAss $VERSION_ASS"
    cd "$SRC_PATH" || return

    if [[ "$OS" == "redhat" ]]; then
        installFribidi
    fi

    if [[ ! -d "libass" ]]; then
        echo "  - Téléchargement libass"
        git clone --depth 1 --branch "$VERSION_ASS" https://github.com/libass/libass.git
    else
        echo "  - libass déjà téléchargé"
    fi

    if true; then # améliorer le true
        echo "  - Compilation libass"

        if [[ "$OS" == "redhat" ]]; then
            yum -y install harfbuzz-devel
        fi

        #redhat: PATH="$BIN_PATH:$PATH" PKG_CONFIG_PATH="$BUILD_PATH/lib/pkgconfig" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --disable-shared --enable-static --disable-require-system-font-provider && \
        #darwin: PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \

        cd libass && \
        ./autogen.sh && \
        PATH="$BIN_PATH:$PATH" PKG_CONFIG_PATH="$BUILD_PATH/lib/pkgconfig" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --disable-shared --enable-static && \
        PATH="$BIN_PATH:$PATH" make -j "${CPU_COUNT}" && \
        make install
    else
        echo "  - libass déjà compilé"
    fi
}

##
# fribidi nécessaire à libass
# note: version 1.0.2-1.el7 dans base
##
installFribidi()
{
    echo "  - installFribidi $VERSION_FRIBIDI"
    cd "$SRC_PATH" || return

    # which pour autogen.sh de fribidi
    if [[ "$OS" == "redhat" ]]; then
        yum -y install which
    fi
    if [[ "$OS" == "debian" ]]; then
        apt -y install which
    fi

    if [[ ! -d "fribidi-$VERSION_FRIBIDI" ]]; then
        # @see https://github.com/fribidi/fribidi/issues/8
        echo "  - Téléchargemeng Fribidi"
        curl -O -L "https://github.com/fribidi/fribidi/releases/download/v${VERSION_FRIBIDI}/fribidi-${VERSION_FRIBIDI}.tar.xz"
        tar xvf "fribidi-${VERSION_FRIBIDI}.tar.xz" && \
        rm "fribidi-${VERSION_FRIBIDI}.tar.xz"
    else
        echo "  - Fribidi déjà téléchargé"
    fi

    if true; then # améliorer le true
        echo "  - Compilation Fribidi"
        echo "fribidi-${VERSION_FRIBIDI}"
        cd "fribidi-${VERSION_FRIBIDI}" && \
        ./autogen.sh && \
        ./configure --prefix="${BUILD_PATH}" --bindir="${BIN_PATH}" --disable-shared --enable-static && \
        make -j "${CPU_COUNT}" -C lib && \
        make install
    else
        echo "  - Fribidi déjà compilé"
    fi
}

installLibMp3Lame()
{
    echo "  - installLibMp3Lame $VERSION_MP3LAME"
    cd "$SRC_PATH" || return

    if [[ ! -d "lame-$VERSION_MP3LAME" ]]; then
        echo "  - Téléchargement lame"
        curl -O -L "https://downloads.sourceforge.net/project/lame/lame/$VERSION_MP3LAME/lame-$VERSION_MP3LAME.tar.gz"
        tar xzvf "lame-$VERSION_MP3LAME.tar.gz"
    else
        echo "  - lame déjà téléchargé"
    fi

    if [[ ! -f "$BUILD_PATH/lib/libmp3lame.a" ]] || [[ ! -f "$BUILD_PATH/lib/libmp3lame.la" ]]; then
        echo "  - Compilation lame"
        cd "lame-$VERSION_MP3LAME" && \
        PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --disable-shared --enable-nasm && \
        PATH="$BIN_PATH:$PATH" make -j "$CPU_COUNT" && \
        make install
    else
        echo "  - lame déjà compilé"
    fi
}

installLibOpus()
{
    echo "  - installLibOpus $VERSION_OPUS"
    cd "$SRC_PATH" || return

    if [[ ! -d "opus-$VERSION_OPUS" ]]; then
        echo "  - Téléchargement opus"
        curl -O -L "https://archive.mozilla.org/pub/opus/opus-$VERSION_OPUS.tar.gz"
        tar xzvf "opus-$VERSION_OPUS.tar.gz"
    else
        echo "  - opus déjà téléchargé"
    fi

    if [[ ! -f "$BUILD_PATH/lib/libopus.a" ]] || [[ ! -f "$BUILD_PATH/lib/libopus.la" ]]; then
        echo "  - Compilation opus"
        cd "opus-$VERSION_OPUS" && \
        PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --disable-shared && \
        PATH="$BIN_PATH:$PATH" make -j "$CPU_COUNT" && \
        make install
    else
        echo "  - opus déjà compilé"
    fi
}

# bien pour anglais, bof pour français
installFlite()
{
    echo "  - Installation Flite $VERSION_FLITE"
    cd "$SRC_PATH" || return

    if [[ ! -d "flite" ]]; then
        echo "  - Téléchargement flite"
        git clone --depth 1 --branch "$VERSION_FLITE" https://github.com/festvox/flite.git
    else
        echo "  - flite déjà téléchargé"
    fi

    if [[ ! -f "$BIN_PATH/flite" ]]; then
        echo "  - Compilation flite"
        cd flite && \
        PATH="$BIN_PATH:$PATH" ./configure --prefix="$BUILD_PATH" --bindir="$BIN_PATH" --enable-static && \
        PATH="$BIN_PATH:$PATH" make -j "${CPU_COUNT}" && \
        make install
    else
        echo "  - flite déjà compilé"
    fi
}

##
# ffmpeg
# note CentOS7: pas dispo dans base ni epel
# note darwin: pas extra-libs -lpthread et -lm ?
##
installFfmpeg()
{
    echo "  - installFfmpeg $VERSION_FFMPEG"
    cd "$SRC_PATH" || return

    if [[ ! -d "ffmpeg-$VERSION_FFMPEG" ]]; then
        echo "  - Téléchargement ffmpeg $VERSION_FFMPEG"
        curl -O -L "https://ffmpeg.org/releases/ffmpeg-$VERSION_FFMPEG.tar.bz2" && \
        tar xjvf "ffmpeg-$VERSION_FFMPEG.tar.bz2"
    else
        echo "  - ffmpeg déjà téléchargé"
    fi

    if true; then
        echo "  - Compilation ffmpeg $VERSION_FFMPEG"
        cd "ffmpeg-$VERSION_FFMPEG" && \
        PATH="$BIN_PATH:$PATH" PKG_CONFIG_PATH="$BUILD_PATH/lib/pkgconfig" ./configure \
        --prefix="$BUILD_PATH" \
        --pkg-config-flags="--static" \
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
