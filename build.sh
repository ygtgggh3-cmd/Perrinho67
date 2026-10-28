#!/usr/bin/env bash
# Perrinho67 - ISO ligera para PCs antiguas, basada en Debian 13 (Trixie)
# Ejecutar como root en Debian/Ubuntu:  sudo ./build.sh
set -euo pipefail

NAME="Perrinho67"
SUITE="trixie"
ARCH="amd64"   # Debian 13 ya no ofrece i386

apt-get update
apt-get install -y live-build debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools

mkdir -p work && cd work
lb clean --purge || true

lb config \
  --distribution "$SUITE" \
  --architectures "$ARCH" \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debian-installer none \
  --bootappend-live "boot=live components quiet splash username=liviano hostname=${NAME,,}" \
  --iso-application "$NAME" \
  --iso-volume "$NAME" \
  --linux-flavours amd64 \
  --binary-images iso-hybrid \
  --memtest none \
  --apt-recommends false \
  --apt-indices false \
  --chroot-squashfs-compression-type xz

mkdir -p config/package-lists
cat > config/package-lists/liviano.list.chroot <<'EOF'
# Sistema base
linux-image-amd64
live-boot
live-config
firmware-linux-free
firmware-linux-nonfree
firmware-misc-nonfree
firmware-realtek
firmware-iwlwifi
network-manager
network-manager-gnome
sudo
# Escritorio ligero (XFCE sin extras)
xfce4
xfce4-terminal
lightdm
lightdm-gtk-greeter
thunar
mousepad
ristretto
# Apariencia tipo Win11 + toque Mac
plank
xfce4-whiskermenu-plugin
xfce4-settings
gtk2-engines-murrine
sassc
git
# Tienda de apps y ahorro de RAM
flatpak
gnome-software
gnome-software-plugin-flatpak
zram-tools
# Ajustes rápidos en la barra (volumen, Bluetooth, red, batería)
xfce4-pulseaudio-plugin
xfce4-power-manager
xfce4-power-manager-plugins
blueman
bluez
# Aplicaciones ligeras
firefox-esr
mpv
# Instalador
calamares
calamares-settings-debian
# Audio
pipewire-audio
pavucontrol
EOF

# --- Tema: WhiteSur (bordes redondeados, estilo Mac) ---
mkdir -p config/hooks/live
cat > config/hooks/live/0100-tema.hook.chroot <<'EOF'
#!/bin/sh
set -e
cd /tmp
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
(cd WhiteSur-gtk-theme && ./install.sh -d /usr/share/themes -c Light)
(cd WhiteSur-icon-theme && ./install.sh -d /usr/share/icons)
rm -rf /tmp/WhiteSur-*
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
# Quitar lo que no se necesita para ahorrar espacio y RAM
apt-get purge -y git sassc || true
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/man/*
EOF
chmod +x config/hooks/live/0100-tema.hook.chroot

# --- Configuración por defecto del usuario ---
SKEL=config/includes.chroot/etc/skel/.config
mkdir -p "$SKEL/xfce4/xfconf/xfce-perchannel-xml" "$SKEL/autostart"

cat > "$SKEL/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="WhiteSur-Light"/>
    <property name="IconThemeName" type="string" value="WhiteSur"/>
  </property>
</channel>
EOF

# Dock inferior centrado (estilo barra de Windows 11)
cat > "$SKEL/autostart/plank.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Dock
Exec=plank
EOF

# La tienda no debe correr en segundo plano (ahorra RAM)
cat > "$SKEL/autostart/gnome-software-service.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=gnome-software-service
Hidden=true
EOF

# Panel superior: menú a la izquierda; bandeja (Wi-Fi, Bluetooth), volumen, batería y reloj a la derecha
cat > "$SKEL/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="30"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="whiskermenu"/>
    <property name="plugin-2" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-3" type="string" value="systray"/>
    <property name="plugin-4" type="string" value="pulseaudio"/>
    <property name="plugin-5" type="string" value="power-manager-plugin"/>
    <property name="plugin-6" type="string" value="clock"/>
  </property>
</channel>
EOF

lb build
echo "Listo: busca la ISO en $(pwd)/live-image-${ARCH}.hybrid.iso"
