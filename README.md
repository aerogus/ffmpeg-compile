# Scripts de compilation FFMPEG

Ce projet regroupe des scripts de compilation FFMPEG pour plusieurs plateformes mais avec MacOS comme système hôte.

modules supportés par les scripts :

- libx264 (codec vidéo)
- libx265 (codec vidéo)
- libass (génération sous-titrage)
- libfdk_aac (codec audio)
- libmp3lame (codec mp3)

## MacOS

Prérequis `homebrew` trouvable ici : https://brew.sh/index_fr

puis

```
./run-macos.sh
```

## Debian 11

Prérequis `docker` activé (sauf si compilation dans l'environnement cible).

Compilation dans un conteneur `Docker`. On récupère les binaires dans `./debian/bin` sur le système hôte `MacOS`.

```
docker run --rm --mount type=bind,source=$(pwd),target=/root -w /root -it debian:11.5 ./run-debian.sh
```

Les fichiers compilés sont dans `./debian/bin`.

## CentOS 7

Prérequis `docker` activé (sauf si compilation dans l'environnement cible).

Compilation dans un conteneur Docker. On récupère les binaires dans `./centos/bin` sur le système hôte `MacOS`.

```
docker run --rm --mount type=bind,source=$(pwd),target=/root -w /root -it centos:7.9.2009 ./run-centos.sh
```

Les fichiers compilés sont dans `./centos/bin`.
