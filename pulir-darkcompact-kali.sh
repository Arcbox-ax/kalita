#!/usr/bin/env bash
set -e

echo "[+] Ajustando terminal XFCE: fondo sólido, sin transparencia..."

mkdir -p ~/.config/xfce4/terminal
cp ~/.config/xfce4/terminal/terminalrc ~/.config/xfce4/terminal/terminalrc.bak.$(date +%F-%H%M) 2>/dev/null || true

cat > ~/.config/xfce4/terminal/terminalrc <<'TERMINAL'
[Configuration]
FontName=Monospace 9
MiscAlwaysShowTabs=FALSE
MiscMenubarDefault=FALSE
MiscToolbarDefault=FALSE
MiscBordersDefault=TRUE
MiscBell=FALSE
MiscConfirmClose=FALSE
ScrollingBar=TERMINAL_SCROLLBAR_NONE
BackgroundMode=TERMINAL_BACKGROUND_SOLID
ColorForeground=#dcdcdc
ColorBackground=#1f2227
ColorCursor=#ffffff
ColorPalette=#1f2227;#cc5555;#55aa55;#d7ba7d;#579bd5;#b777d5;#56b6c2;#dddddd;#666666;#ff7777;#77cc77;#ffd479;#79b8ff;#d19aff;#80d8e8;#ffffff
TERMINAL

echo "[+] Mejorando panel inferior..."

PANELS=$(xfconf-query -c xfce4-panel -p /panels 2>/dev/null | grep -Eo 'panel-[0-9]+' || true)

for PANEL in $PANELS; do
  xfconf-query -c xfce4-panel -p /panels/$PANEL/size -s 24 2>/dev/null || true
  xfconf-query -c xfce4-panel -p /panels/$PANEL/nrows -s 1 2>/dev/null || true
  xfconf-query -c xfce4-panel -p /panels/$PANEL/background-style -s 1 2>/dev/null || true
  xfconf-query -c xfce4-panel -p /panels/$PANEL/background-rgba \
    -t double -t double -t double -t double \
    -s 0.12 -s 0.13 -s 0.15 -s 1.0 2>/dev/null || true
done

echo "[+] Forzando CSS oscuro más limpio para panel y escritorio..."

mkdir -p ~/.config/gtk-3.0
CSS="$HOME/.config/gtk-3.0/gtk.css"
cp "$CSS" "$CSS.bak.$(date +%F-%H%M)" 2>/dev/null || true

sed -i '/\/\* ROBINSON-DARK-PULIDO-INICIO \*\//,/\/\* ROBINSON-DARK-PULIDO-FIN \*\//d' "$CSS" 2>/dev/null || true

cat >> "$CSS" <<'GTKCSS'

/* ROBINSON-DARK-PULIDO-INICIO */

/* Panel inferior XFCE */
.xfce4-panel {
    background-color: #1f2227;
    color: #dddddd;
    border: none;
    box-shadow: none;
}

.xfce4-panel button {
    background-color: transparent;
    color: #dddddd;
    border: none;
    box-shadow: none;
    padding: 0px 4px;
    margin: 0px;
    min-height: 18px;
    min-width: 18px;
}

.xfce4-panel button:hover {
    background-color: #30343b;
}

.xfce4-panel .tasklist button {
    background-color: transparent;
    color: #dddddd;
    border-radius: 0;
    padding: 0px 5px;
    margin: 0px;
}

.xfce4-panel .tasklist button:checked {
    background-color: #3a3f48;
}

/* Menús GTK */
menu,
.menu,
.context-menu {
    background-color: #252932;
    color: #dddddd;
}

menuitem:hover,
.menuitem:hover {
    background-color: #3a3f48;
}

/* ROBINSON-DARK-PULIDO-FIN */
GTKCSS

echo "[+] Creando fondo oscuro simple para reemplazar el beige..."

mkdir -p ~/Imágenes

if command -v convert >/dev/null 2>&1; then
  convert -size 1920x1080 gradient:'#1b1e23-#2a2d34' ~/Imágenes/wallpaper-darkcompact.png
elif command -v magick >/dev/null 2>&1; then
  magick -size 1920x1080 gradient:'#1b1e23-#2a2d34' ~/Imágenes/wallpaper-darkcompact.png
else
  echo "[!] No encontré ImageMagick. No pude crear wallpaper automático."
fi

if [ -f ~/Imágenes/wallpaper-darkcompact.png ]; then
  echo "[+] Aplicando wallpaper oscuro en todos los monitores detectados..."
  xfconf-query -c xfce4-desktop -lv | awk '/last-image/ {print $1}' | while read -r PROP; do
    xfconf-query -c xfce4-desktop -p "$PROP" -s "$HOME/Imágenes/wallpaper-darkcompact.png" 2>/dev/null || true
  done
fi

echo "[+] Reiniciando panel, escritorio y decorador..."
xfce4-panel -r 2>/dev/null || true
xfdesktop --reload 2>/dev/null || true
xfwm4 --replace >/dev/null 2>&1 &

echo
echo "[OK] Pulido aplicado."
echo "Cierra y abre la terminal para ver el cambio sólido."
