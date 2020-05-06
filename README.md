# Compilation de FFMPEG

Ce projet regroupe des scripts de compilation FFMPEG pour plusieurs plateformes mais avec MacOS comme système hôte.

modules supportés par les scripts :

* libx264 (codec vidéo)
* libx265 (codec vidéo)
* libass (génération sous titrage)
* libfdk_aac (codec audio)
* libndi_newtek (stream via le réseau) support max ffmpeg 4.1.5 pour des soucis de licence

SDK de NDI : (200Mo)
* http://new.tk/NDISDK
* http://new.tk/NDISDKAPPLE
* http://new.tk/NDISDKLINUX
* http://new.tk/ndisdk_license/

Runtine NDI : (1.5Mo)
* http://new.tk/NDIRedistV4Apple

## MacOS

Prérequis:

* homebrew: https://brew.sh/index_fr

Compilation native. On récupère les binaires dans ~/bin sur le système

les fichiers NDI à importer pour la compilation :
cp /Library/NDI\ SDK\ for\ Apple/include/*.* ffmpeg_build/include
cp /Library/NDI\ SDK\ for\ Apple/lib/x64/libndi.4.dylib ffmpeg_build/libndi.dylib

```
./run-macos.sh
```

FIX post compil
```
install_name_tool -change @rpath/libndi.4.dylib /Library/NDI\ SDK\ for\ Apple/lib/x64/libndi.4.dylib ffmpeg
install_name_tool -change @rpath/libndi.4.dylib /Library/NDI\ SDK\ for\ Apple/lib/x64/libndi.4.dylib ffprobe
install_name_tool -change @rpath/libndi.4.dylib /Library/NDI\ SDK\ for\ Apple/lib/x64/libndi.4.dylib ffplay
```

ou mieux ! installer le runtine libNDI_for_Mac.pkg (1.5Mo)

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

Streamer une mire en NDI, avec une source nommée 'jojo'

ffmpeg -re -f lavfi -i smptebars -crf 18 -s 1280x720 -r 25 -pix_fmt uyvy422 -f libndi_newtek 'jojo'

Lister les sources NDI trouvées sur le réseau local :

./ffmpeg -f libndi_newtek -find_sources 1 -i dummy

[libndi_newtek @ 0x7fccb6808200] Found 1 NDI sources:
[libndi_newtek @ 0x7fccb6808200] 	'MAC-MINI-BUREAU-1.LOCAL (jojo)'	'127.0.0.1:5961'

Lire une source NDI :

ffplay -f libndi_newtek -i 'IPHONE-GUILLAUME (NDI HX Camera)'
ffplay -f libndi_newtek -i 'jojo'

OBS peut importer des sources NDI via un plugin :
https://github.com/Palakis/obs-ndi/releases/tag/4.9.0 (pour OBS 25)

Ressources NDI :

