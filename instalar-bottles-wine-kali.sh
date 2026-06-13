#!/usr/bin/env bash
set -e

echo "[+] Instalando Bottles + Wine en Kali"
echo

echo "[+] Arquitectura detectada:"
dpkg --print-architecture

echo "[+] Habilitando soporte i386 para apps Windows de 32 bits..."
sudo dpkg --add-architecture i386

echo "[+] Actualizando repositorios..."
sudo apt update

echo "[+] Instalando Wine y herramientas útiles..."
sudo apt install -y \
  wine \
  wine64 \
  wine32 \
  winetricks \
  cabextract \
  p7zip-full \
  unzip \
  fonts-wine \
  dbus-x11

echo "[+] Instalando Flatpak e integración gráfica..."
sudo apt install -y \
  flatpak \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  gnome-software-plugin-flatpak

echo "[+] Agregando Flathub..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "[+] Instalando Bottles desde Flathub..."
flatpak install -y flathub com.usebottles.bottles

echo "[+] Creando carpetas básicas de Wine..."
mkdir -p "$HOME/.wine"

echo "[+] Inicializando Wine..."
wineboot -u || true

echo "[+] Actualizando base de datos de menú..."
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
sudo update-desktop-database /usr/share/applications 2>/dev/null || true

echo
echo "[OK] Instalación terminada."
echo
echo "Para abrir Bottles:"
echo "  flatpak run com.usebottles.bottles"
echo
echo "Para probar Wine:"
echo "  wine --version"
echo "  winecfg"
echo
echo "Si Bottles no aparece en el menú, cierra sesión y vuelve a entrar."
