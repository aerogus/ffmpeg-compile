# Compilation FFMPEG

## MacOS

Installer homebrew
Exécuter ./run-macos.sh

## Debian Stretch 9

docker pull debian
docker run --mount type=bind,source=/Users/gus/workspace/ffmpeg,target=/ffmpeg -i -t centos
Exécuter dans le container /ffmpeg/run-debian.sh

## CentOS 7

Récupérer l'image de base centos et y exécuter les phases de compil

docker pull centos
docker run --mount type=bind,source=/Users/gus/workspace/ffmpeg,target=/ffmpeg -i -t centos /ffmpeg/run-centos.sh

les fichiers compilés sont dans ./ffmpeg/bin

