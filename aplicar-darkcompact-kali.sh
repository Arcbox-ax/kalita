#!/usr/bin/env bash
set -euo pipefail

THEME_NAME="Darkcompact"
THEME_DIR="$HOME/.themes/$THEME_NAME"
BACKUP_DIR="$HOME/.config/backup-darkcompact-$(date +%F-%H%M%S)"
PANEL_COLOR="#2b2b2b"

mkdir -p "$BACKUP_DIR"

echo "[+] Guardando respaldo en: $BACKUP_DIR"
xfconf-query -c xsettings -lv > "$BACKUP_DIR/xsettings.txt" 2>/dev/null || true
xfconf-query -c xfwm4 -lv > "$BACKUP_DIR/xfwm4.txt" 2>/dev/null || true
xfconf-query -c xfce4-panel -lv > "$BACKUP_DIR/xfce4-panel.txt" 2>/dev/null || true

if [ ! -d "$THEME_DIR" ]; then
  echo "[!] No existe $THEME_DIR"
  echo "    Revisa con: ls -la ~/.themes"
  exit 1
fi

echo "[+] Verificando estructura del tema..."
if [ ! -d "$THEME_DIR/xfwm4" ]; then
  echo "[!] Advertencia: $THEME_DIR no tiene carpeta xfwm4."
  echo "    El tema GTK se aplicará, pero los bordes/botones quizá no cambien."
fi

if [ ! -d "$THEME_DIR/gtk-3.0" ]; then
  echo "[!] Advertencia: $THEME_DIR no tiene carpeta gtk-3.0."
fi

echo "[+] Aplicando tema GTK y tema de ventanas..."
xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "$THEME_NAME" 2>/dev/null || \
xfconf-query -c xsettings -p /Net/ThemeName -s "$THEME_NAME"

xfconf-query -c xfwm4 -p /general/theme -n -t string -s "$THEME_NAME" 2>/dev/null || \
xfconf-query -c xfwm4 -p /general/theme -s "$THEME_NAME"

echo "[+] Aplicando iconos oscuros si existen..."
if [ -d /usr/share/icons/Flat-Remix-Blue-Dark ] || [ -d "$HOME/.icons/Flat-Remix-Blue-Dark" ]; then
  ICON_THEME="Flat-Remix-Blue-Dark"
elif [ -d /usr/share/icons/Papirus-Dark ] || [ -d "$HOME/.icons/Papirus-Dark" ]; then
  ICON_THEME="Papirus-Dark"
else
  ICON_THEME="Adwaita"
fi

xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "$ICON_THEME" 2>/dev/null || \
xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_THEME"

echo "[+] Dejando fuentes compactas..."
xfconf-query -c xsettings -p /Gtk/FontName -n -t string -s "Noto Sans 9" 2>/dev/null || \
xfconf-query -c xsettings -p /Gtk/FontName -s "Noto Sans 9"

xfconf-query -c xfwm4 -p /general/title_font -n -t string -s "Noto Sans Bold 8" 2>/dev/null || \
xfconf-query -c xfwm4 -p /general/title_font -s "Noto Sans Bold 8"

echo "[+] Normalizando escala para evitar botones gigantes..."
xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -n -t int -s 1 2>/dev/null || \
xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -s 1

xfconf-query -c xsettings -p /Xft/DPI -n -t int -s 96 2>/dev/null || \
xfconf-query -c xsettings -p /Xft/DPI -s 96

echo "[+] Escribiendo configuración GTK 2/3/4..."
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

[ -f "$HOME/.gtkrc-2.0" ] && cp "$HOME/.gtkrc-2.0" "$BACKUP_DIR/gtkrc-2.0.bak"
[ -f "$HOME/.config/gtk-3.0/settings.ini" ] && cp "$HOME/.config/gtk-3.0/settings.ini" "$BACKUP_DIR/gtk3-settings.ini.bak"
[ -f "$HOME/.config/gtk-4.0/settings.ini" ] && cp "$HOME/.config/gtk-4.0/settings.ini" "$BACKUP_DIR/gtk4-settings.ini.bak"

cat > "$HOME/.gtkrc-2.0" <<GTK2
gtk-theme-name="$THEME_NAME"
gtk-icon-theme-name="$ICON_THEME"
gtk-font-name="Noto Sans 9"
GTK2

cat > "$HOME/.config/gtk-3.0/settings.ini" <<GTK3
[Settings]
gtk-theme-name=$THEME_NAME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Noto Sans 9
gtk-application-prefer-dark-theme=1
GTK3

cat > "$HOME/.config/gtk-4.0/settings.ini" <<GTK4
[Settings]
gtk-theme-name=$THEME_NAME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Noto Sans 9
gtk-application-prefer-dark-theme=1
GTK4

echo "[+] Forzando panel XFCE oscuro compacto..."
CSS="$HOME/.config/gtk-3.0/gtk.css"
[ -f "$CSS" ] && cp "$CSS" "$BACKUP_DIR/gtk.css.bak"

# Eliminar bloque anterior si existe
if [ -f "$CSS" ]; then
  sed -i '/\/\* DARKCOMPACT-KALI-INICIO \*\//,/\/\* DARKCOMPACT-KALI-FIN \*\//d' "$CSS"
fi

cat >> "$CSS" <<'GTKCSS'

/* DARKCOMPACT-KALI-INICIO */
.xfce4-panel {
    background-color: #2b2b2b;
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
}

.xfce4-panel button:hover {
    background-color: #3a3a3a;
}

.xfce4-panel .tasklist button {
    background-color: transparent;
    color: #dddddd;
    border-radius: 0;
    padding: 0px 5px;
    margin: 0px;
}

.xfce4-panel .tasklist button:checked {
    background-color: #444444;
}
/* DARKCOMPACT-KALI-FIN */
GTKCSS

echo "[+] Ajustando todos los paneles detectados..."
PANELS=$(xfconf-query -c xfce4-panel -p /panels 2>/dev/null | grep -Eo 'panel-[0-9]+' || true)

if [ -z "$PANELS" ]; then
  PANELS="panel-1"
fi

for PANEL in $PANELS; do
  echo "    - $PANEL"

  xfconf-query -c xfce4-panel -p /panels/$PANEL/mode -n -t int -s 0 2>/dev/null || \
  xfconf-query -c xfce4-panel -p /panels/$PANEL/mode -s 0 2>/dev/null || true

  xfconf-query -c xfce4-panel -p /panels/$PANEL/nrows -n -t uint -s 1 2>/dev/null || \
  xfconf-query -c xfce4-panel -p /panels/$PANEL/nrows -s 1 2>/dev/null || true

  xfconf-query -c xfce4-panel -p /panels/$PANEL/size -n -t uint -s 24 2>/dev/null || \
  xfconf-query -c xfce4-panel -p /panels/$PANEL/size -s 24 2>/dev/null || true

  xfconf-query -c xfce4-panel -p /panels/$PANEL/length -n -t uint -s 100 2>/dev/null || \
  xfconf-query -c xfce4-panel -p /panels/$PANEL/length -s 100 2>/dev/null || true

  xfconf-query -c xfce4-panel -p /panels/$PANEL/length-adjust -n -t bool -s true 2>/dev/null || \
  xfconf-query -c xfce4-panel -p /panels/$PANEL/length-adjust -s true 2>/dev/null || true

  xfconf-query -c xfce4-panel -p /panels/$PANEL/position-locked -n -t bool -s true 2>/dev/null || \
  xfconf-query -c xfce4-panel -p /panels/$PANEL/position-locked -s true 2>/dev/null || true

  # 1 = color sólido en muchas versiones de XFCE
  xfconf-query -c xfce4-panel -p /panels/$PANEL/background-style -n -t int -s 1 2>/dev/null || \
  xfconf-query -c xfce4-panel -p /panels/$PANEL/background-style -s 1 2>/dev/null || true

  xfconf-query -c xfce4-panel -p /panels/$PANEL/background-rgba \
    -t double -t double -t double -t double \
    -s 0.17 -s 0.17 -s 0.17 -s 1.0 2>/dev/null || true
done

echo "[+] Configurando terminal XFCE estilo Darkcompact..."
mkdir -p "$HOME/.config/xfce4/terminal"
[ -f "$HOME/.config/xfce4/terminal/terminalrc" ] && \
  cp "$HOME/.config/xfce4/terminal/terminalrc" "$BACKUP_DIR/terminalrc.bak"

cat > "$HOME/.config/xfce4/terminal/terminalrc" <<'TERMINAL'
[Configuration]
FontName=Monospace 9
MiscAlwaysShowTabs=FALSE
MiscMenubarDefault=FALSE
MiscToolbarDefault=FALSE
MiscBordersDefault=TRUE
ScrollingBar=TERMINAL_SCROLLBAR_NONE
ColorForeground=#dcdcdc
ColorBackground=#2b2b2b
ColorCursor=#ffffff
ColorPalette=#2b2b2b;#cc5555;#55aa55;#d7ba7d;#579bd5;#b777d5;#56b6c2;#dddddd;#666666;#ff7777;#77cc77;#ffd479;#79b8ff;#d19aff;#80d8e8;#ffffff
TERMINAL

echo "[+] Intentando aplicar tema oscuro a Mousepad..."
gsettings set org.xfce.mousepad.preferences.view color-scheme Kali-Dark 2>/dev/null || true

echo "[+] Reiniciando panel y decorador de ventanas..."
xfce4-panel -r 2>/dev/null || true
sleep 1
xfwm4 --replace >/dev/null 2>&1 & disown || true

echo
echo "[OK] Darkcompact aplicado."
echo "[OK] Respaldo: $BACKUP_DIR"
echo
echo "Nota Chrome/Firefox:"
echo " - Chrome/Chromium: clic derecho en barra de pestañas -> activar 'Use system title bar and borders'."
echo " - Firefox: Menú -> Más herramientas -> Personalizar barra -> activar 'Title Bar'."
echo
echo "Recomendado: cerrar sesión y volver a entrar para que GTK/Firefox/Chrome tomen todo bien."
