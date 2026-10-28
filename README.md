# Perrinho67

Distribución Linux ligera para PCs antiguas. Base: Debian 13 (Trixie), amd64, escritorio XFCE, instalador Calamares.

## Construir la ISO
En un Debian/Ubuntu (puede ser una VM), como root:

    sudo ./build.sh

La ISO queda en `work/live-image-amd64.hybrid.iso`.

## Probar
Abre la ISO en VirtualBox/QEMU con 1-2 GB de RAM, o grábala en un USB con Rufus/balenaEtcher.

## Personalizar
- Paquetes: edita la lista dentro de `build.sh`.
- Nombre: cambia `NAME` al inicio de `build.sh`.

## Próximos pasos
- Tema, fondos de pantalla y logo propios
- Servicios innecesarios desactivados para ahorrar RAM
- Repositorio en GitHub
