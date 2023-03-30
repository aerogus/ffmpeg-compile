# Scripts de compilation FFMPEG

Ce projet regroupe des scripts de compilation FFMPEG pour plusieurs plateformes mais avec MacOS comme système hôte.

modules supportés par les scripts :

- libx264 (codec vidéo)
- libx265 (codec vidéo)
- libass (génération sous-titrage)
- libfdk_aac (codec audio)
- libmp3lame (codec mp3)

Prérequis: copier le fichier de configuration d'exemple et l'adapter

```bash
cp conf.ini.dist.sh conf.ini.sh
```

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
docker run --rm --mount type=bind,source=$(pwd),target=/app -w /app -it debian:11.6 ./run-debian.sh
```

## CentOS 7

Prérequis `docker` activé (sauf si compilation dans l'environnement cible).

Compilation dans un conteneur Docker. On récupère les binaires dans `./centos/bin` sur le système hôte `MacOS`.

```
docker run --rm --mount type=bind,source=$(pwd),target=/app -w /app -it centos:7.9.2009 ./run-centos.sh
```

