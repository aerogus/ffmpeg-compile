# Compilation FFMPEG

Ce projet regroupe les fonctions nécessaires à la compilation de FFMPEG pour les plateformes cibles suivantes MacOS Ventura, CentOS 7, Debian 11.
Il n'est pas exclu que la compilation fonctionne sous d'autres plateformes/OS. Contributions bienvenues.

## Modules supportés :

- libfdk_aac (Fraunhofer FDK AAC)
- libmp3lame (codec pour MPEG 1 Layer III)
- libass (génération sous-titrage)
- libx264 (codec pour vidéo H.264/AVC)
- libx265 (codec pour vidéo H.265/HEVC)
- libfreetype (pour drawtext)
- libfontconfig (fallback font par défaut)
- libflite (WIP) (text 2 speech) darwin only

## Installation

Copier le fichier de configuration d'exemple et l'adapter (choix des versions et des modules à activer)

```bash
cp conf.ini.dist.sh conf.ini.sh
```

## MacOS

Prérequis `homebrew` trouvable ici : https://brew.sh/index_fr

puis

```bash
./run.sh
```

Les binaires statiques sont écrits dans `./bin/darwin`.

## Debian 11

Prérequis `docker` activé (sauf si compilation dans l'environnement cible).

Compilation dans un conteneur `Docker`. On récupère les binaires statiques dans `./bin/debian` sur le système hôte `MacOS`.

```
docker run --rm --mount type=bind,source=$(pwd),target=/app -w /app -it debian:11.6 ./run.sh
```

## CentOS 7

Prérequis `docker` activé (sauf si compilation dans l'environnement cible).

Compilation dans un conteneur Docker. On récupère les binaires statiques dans `./bin/redhat` sur le système hôte `MacOS`.

```
docker run --rm --mount type=bind,source=$(pwd),target=/app -w /app -it centos:7.9.2009 ./run.sh
```

## Ressources

- https://trac.ffmpeg.org/wiki/CompilationGuide/Generic
- https://trac.ffmpeg.org/wiki/CompilationGuide/macOS
- https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
- https://trac.ffmpeg.org/wiki/CompilationGuide/Centos
