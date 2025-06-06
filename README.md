# Compilation FFMPEG

Ce projet regroupe les fonctions nécessaires à la compilation de FFMPEG pour les plateformes cibles suivantes MacOS Ventura, CentOS 7, Debian 12.
Il n'est pas exclu que la compilation fonctionne sous d'autres plateformes/OS. Contributions bienvenues.

## Modules supportés :

- `libmp3lame` (codec pour MPEG 1 Layer III)
- `libfdk_aac` (Fraunhofer FDK AAC)
- `libopus`
- `libx264` (codec pour vidéo H.264/AVC)
- `libx265` (codec pour vidéo H.265/HEVC)
- `libass` (génération sous-titrage)
- `libfreetype` (pour drawtext)
- `libfontconfig` (fallback font par défaut)
- `libflite` (WIP) (text 2 speech) darwin only
- `openssl` (pour https)
- `libzimg` (filtre zscale)

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

Les binaires statiques sont écrits dans `./bin`.

## Debian 12.8

Prérequis `docker` activé (sauf si compilation dans l'environnement cible).

Compilation dans un conteneur `Docker`. On récupère les binaires statiques dans `./bin` sur le système hôte `MacOS`.

```bash
docker run --rm --mount type=bind,source=$(pwd),target=/app -w /app -it debian:12.8 ./run.sh
```

## AlmaLinux 9.5

Prérequis `docker` activé (sauf si compilation dans l'environnement cible).

Compilation dans un conteneur `Docker`. On récupère les binaires statiques dans `./bin` sur le système hôte `MacOS`.

```bash
docker run --rm --mount type=bind,source=$(pwd),target=/app -w /app -it almalinux:9.5 ./run.sh
```

## CentOS 7.9 (EOL)

EOL le 30/06/2024. Plus supporté, les dépôts ne répondent plus (il faudrait utiliser vault).

Prérequis `docker` activé (sauf si compilation dans l'environnement cible).

Compilation dans un conteneur Docker. On récupère les binaires statiques dans `./bin` sur le système hôte `MacOS`.

```bash
docker run --rm --mount type=bind,source=$(pwd),target=/app -w /app -it centos:7.9.2009 ./run.sh
```

## Ressources

- https://trac.ffmpeg.org/wiki/CompilationGuide/Generic
- https://trac.ffmpeg.org/wiki/CompilationGuide/macOS
- https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
- https://trac.ffmpeg.org/wiki/CompilationGuide/Centos
