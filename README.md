# Compilation FFMPEG multiplateforme

## MacOS

Installer homebrew

```
./run-macos.sh
```

## Debian Stretch 9

```
docker run --rm --name debian-ffmpeg --mount type=bind,source=$HOME/workspace/ffmpeg,target=/ffmpeg -w /ffmpeg -it debian
./run-debian.sh
```

## CentOS 7

```
docker run --rm --name centos-ffmpeg --mount type=bind,source=$HOME/workspace/ffmpeg,target=/ffmpeg -w /ffmpeg -it centos
./run-centos.sh
```

les fichiers compilés sont dans /ffmpeg/bin

