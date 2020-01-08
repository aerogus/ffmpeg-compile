# Compilation de FFMPEG

Ce projet regroupe des scripts de compilation FFMPEG pour plusieurs plateformes mais avec MacOS comme système hôte.

modules supportés par les scripts :

- libx264 (codec vidéo)
- libx265 (codec vidéo)
- libass (génération sous titrage)
- libfdk_aac (codec audio)

## MacOS

Prérequis:

* homebrew: https://brew.sh/index_fr

Compilation native. On récupère les binaires dans ~/bin sur le système

```
./run-macos.sh
```

## Debian

Prérequis:

* docker (sauf si compilation dans l'environnement cible)

Compilation dans un conteneur Docker. On récupère les binaires dans ./debian/bin sur le système hôte MacOS
On peut effacer le conteneur par la suite

```
docker run --rm --name debian-ffmpeg --mount type=bind,source=$HOME/workspace/ffmpeg-compile,target=/root -w /root -it debian
./run-debian.sh
```

## CentOS

Prérequis:

* docker (sauf si compilation dans l'environnement cible)

Compilation dans un conteneur Docker. On récupère les binaires dans ./centos/bin sur le système hôte MacOS
On peut effacer le conteneur par la suite

```
docker run --rm --name centos-ffmpeg --mount type=bind,source=$HOME/workspace/ffmpeg-compile,target=/root -w /root -it centos
./run-centos.sh
```

les fichiers compilés sont dans /ffmpeg/bin
