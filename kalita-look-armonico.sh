#!/usr/bin/env bash

echo "[+] Aplicando look kAlita armónico..."

# Tema GTK oscuro coherente
xfconf-query -c xsettings -p /Net/ThemeName -s "Kali-Dark" 2>/dev/null || \
xfconf-query -c xsettings -p /Net/ThemeName -s "Greybird-dark"

# Iconos más sobrios
if [ -d /usr/share/icons/Papirus-Dark ]; then
  xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Dark"
elif [ -d /usr/share/icons/Flat-Remix-Yellow-Dark ]; then
  xfconf-query -c xsettings -p /Net/IconThemeName -s "Flat-Remix-Yellow-Dark"
else
  xfconf-query -c xsettings -p /Net/IconThemeName -s "Adwaita"
fi

# Cursor sobrio
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "Adwaita" 2>/dev/null || true

# Fuente compacta pero legible
xfconf-query -c xsettings -p /Gtk/FontName -s "Noto Sans 9"
xfconf-query -c xfwm4 -p /general/title_font -s "Noto Sans Bold 8"

# Volver a un borde de ventana más normal y oscuro
if [ -d /usr/share/themes/Greybird-dark/xfwm4 ]; then
  xfconf-query -c xfwm4 -p /general/theme -s "Greybird-dark"
elif [ -d /usr/share/themes/Kali-Dark/xfwm4 ]; then
  xfconf-query -c xfwm4 -p /general/theme -s "Kali-Dark"
else
  xfconf-query -c xfwm4 -p /general/theme -s "Default"
fi

# Maximizado sin borde inútil
xfconf-query -c xfwm4 -p /general/borderless_maximize -s true

# Iconos de escritorio más pequeños
xfconf-query -c xfce4-desktop -p /desktop-icons/icon-size -s 32 2>/dev/null || true

# CSS GTK: plomo oscuro + acento naranjo, sin exagerar
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0

cat > ~/.config/gtk-3.0/gtk.css <<'EOF'
/* kAlita armonico */

headerbar,
.titlebar {
    min-height: 24px;
    padding: 0 5px;
    background: #2b2b2b;
    color: #e6a23c;
    border-bottom: 1px solid #1f1f1f;
}

headerbar:backdrop,
.titlebar:backdrop {
    background: #242424;
    color: #8d8d8d;
}

headerbar button,
.titlebar button {
    min-height: 18px;
    min-width: 18px;
    padding: 1px 4px;
    background: transparent;
    color: #dddddd;
    border-radius: 4px;
}

headerbar button:hover,
.titlebar button:hover {
    background: #3a3a3a;
    color: #e6a23c;
}

window decoration {
    border: 1px solid #2b2b2b;
    box-shadow: 0 0 0 1px #1f1f1f;
}

/* KALITA-PANEL-COLOR-INICIO */
.xfce4-panel {
    color: #e6a23c;
}
.xfce4-panel image {
    -gtk-icon-style: symbolic;
    color: #e6a23c;
}
/* KALITA-PANEL-COLOR-FIN */
EOF

cp ~/.config/gtk-3.0/gtk.css ~/.config/gtk-4.0/gtk.css

# Reloj naranja
xfconf-query -c xfce4-panel -p /plugins/plugin-19/digital-time-format \
  -s "<span color='#e6a23c'>%_H:%M</span>" 2>/dev/null || true

# Botón mostrar escritorio: agregar si no existe
PLUGIN_IDS=$(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | grep -o '[0-9]*' | tr '\n' ' ')
if ! xfconf-query -c xfce4-panel -p /plugins/plugin-33 2>/dev/null | grep -q "showdesktop"; then
  # Buscar ID libre
  MAX_ID=$(xfconf-query -c xfce4-panel -l 2>/dev/null | grep "^/plugins/plugin-[0-9]*$" | sed 's|/plugins/plugin-||' | sort -n | tail -1)
  NEW_ID=$((MAX_ID + 1))
  xfconf-query -c xfce4-panel -p /plugins/plugin-$NEW_ID -n -t string -s "showdesktop"
  # Insertar después del primer plugin (posición 2)
  IDS=($(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | grep -o '[0-9]*'))
  TYPES=(); for id in "${IDS[@]}"; do TYPES+=("-t int"); done
  TYPES+=("-t int")
  VALS=("${IDS[0]}" "$NEW_ID" "${IDS[@]:1}")
  SVALS=(); for v in "${VALS[@]}"; do SVALS+=("-s $v"); done
  xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n "${TYPES[@]}" "${SVALS[@]}" 2>/dev/null || true
  echo "[+] Botón showdesktop agregado (plugin-$NEW_ID)"
fi

# Indicador de batería: agregar si no existe ya en el panel
if ! xfconf-query -c xfce4-panel -l 2>/dev/null | xargs -I{} sh -c 'xfconf-query -c xfce4-panel -p {} 2>/dev/null' | grep -q "power-manager-plugin"; then
  MAX_ID=$(xfconf-query -c xfce4-panel -l 2>/dev/null | grep "^/plugins/plugin-[0-9]*$" | sed 's|/plugins/plugin-||' | sort -n | tail -1)
  NEW_ID=$((MAX_ID + 1))
  xfconf-query -c xfce4-panel -p /plugins/plugin-$NEW_ID -n -t string -s "power-manager-plugin"
  # Insertar antes del último plugin (reloj)
  IDS=($(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | grep -o '[0-9]*'))
  LAST="${IDS[-1]}"
  INIT=("${IDS[@]::${#IDS[@]}-1}")
  VALS=("${INIT[@]}" "$NEW_ID" "$LAST")
  TYPES=(); for v in "${VALS[@]}"; do TYPES+=("-t int"); done
  SVALS=(); for v in "${VALS[@]}"; do SVALS+=("-s $v"); done
  xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n "${TYPES[@]}" "${SVALS[@]}" 2>/dev/null || true
  echo "[+] Indicador de batería agregado (plugin-$NEW_ID)"
fi

# Iconos Papirus-Dark: carpetas y wifi/bluetooth naranjos (requiere sudo)
_aplicar_iconos_naranja() {
  PAPIRUS="/usr/share/icons/Papirus-Dark"
  [ -d "$PAPIRUS" ] || return

  # Backup primera vez
  if [ ! -d "${PAPIRUS}-backup-kalita" ]; then
    cp -r "$PAPIRUS" "${PAPIRUS}-backup-kalita"
    echo "[+] Backup creado en ${PAPIRUS}-backup-kalita"
  fi

  # Wifi y bluetooth: gris → naranja
  for size in 16x16 22x22 24x24; do
    for icon in "$PAPIRUS/$size/panel"/network-wireless*.svg "$PAPIRUS/$size/panel"/bluetooth*.svg; do
      [ -f "$icon" ] && [ ! -L "$icon" ] && sed -i 's/color:#dfdfdf/color:#e6a23c/g' "$icon"
    done
  done

  # Carpetas: azul → naranja
  for size in 16x16 22x22 24x24 32x32 48x48 64x64; do
    for icon in "$PAPIRUS/$size/places"/folder*.svg; do
      [ -f "$icon" ] && [ ! -L "$icon" ] && sed -i \
        -e 's/#5294e2/#e6a23c/g' -e 's/#4877b1/#c47a1e/g' \
        -e 's/#3a87e5/#d4891e/g' -e 's/#1d344f/#7a4a0f/g' "$icon"
    done
  done

  # Ícono showdesktop para Papirus-Dark
  for size in 16 22 24; do
    mkdir -p "$PAPIRUS/${size}x${size}/apps"
    cat > "$PAPIRUS/${size}x${size}/apps/org.xfce.panel.showdesktop.svg" <<SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <rect x="1" y="1" width="$((size-2))" height="$((size-2))" rx="2" ry="2" style="fill:#e6a23c;opacity:0.9"/>
  <rect x="$((size/4))" y="$((size*5/8))" width="$((size/4-1))" height="$((size/4))" rx="1" ry="1" style="fill:#ffffff"/>
  <rect x="$((size/2+1))" y="$((size*5/8))" width="$((size/4-1))" height="$((size/4))" rx="1" ry="1" style="fill:#ffffff"/>
</svg>
SVGEOF
  done

  gtk-update-icon-cache -f "$PAPIRUS/" 2>/dev/null || true
  echo "[+] Íconos Papirus-Dark actualizados"
}

# Íconos locales hicolor (Mudlet AppImage, etc.)
_aplicar_iconos_hicolor() {
  MUDLET_SFS="$HOME/Applications/Mudlet/squashfs-root"
  if [ -f "$MUDLET_SFS/mudlet.png" ]; then
    mkdir -p "$HOME/.local/share/icons/hicolor/48x48/apps" \
             "$HOME/.local/share/icons/hicolor/scalable/apps"
    cp "$MUDLET_SFS/mudlet.png" "$HOME/.local/share/icons/hicolor/48x48/apps/mudlet.png"
    [ -f "$MUDLET_SFS/mudlet.svg" ] && \
      cp "$MUDLET_SFS/mudlet.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/mudlet.svg"
    gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
    echo "[+] Ícono Mudlet instalado"
  fi
}

if [ "$(id -u)" = "0" ]; then
  _aplicar_iconos_naranja
elif sudo -n true 2>/dev/null; then
  sudo bash -c "$(declare -f _aplicar_iconos_naranja); _aplicar_iconos_naranja"
else
  echo "[!] Para íconos naranjos (carpetas/wifi/bluetooth) ejecuta con sudo"
fi

_aplicar_iconos_hicolor

# Indicadores docklike: barra naranja bajo apps abiertas
DOCKLIKE_RC=$(find ~/.config/xfce4/panel/ -name "docklike-*.rc" 2>/dev/null | head -1)
if [ -n "$DOCKLIKE_RC" ]; then
  python3 - "$DOCKLIKE_RC" <<'PYEOF'
import sys, re

path = sys.argv[1]
with open(path) as f:
    content = f.read()

settings = {
    "indicatorColor": "rgb(230,162,60)",
    "inactiveColor": "rgb(100,100,100)",
    "indicatorColorFromTheme": "false",
    "indicatorStyle": "0",
    "inactiveIndicatorStyle": "0",
    "indicatorOrientation": "1",
}

for key, val in settings.items():
    if re.search(rf"^{key}=", content, re.MULTILINE):
        content = re.sub(rf"^{key}=.*$", f"{key}={val}", content, flags=re.MULTILINE)
    else:
        content = content.rstrip("\n") + f"\n{key}={val}\n"

with open(path, "w") as f:
    f.write(content)

print(f"[+] Docklike indicadores configurados: {path}")
PYEOF
fi

# Asegurar Conky con acento naranjo
if [ -f ~/.config/conky/conky.conf ]; then
  sed -i "s/color1 = 'cyan'/color1 = '#E6A23C'/g" ~/.config/conky/conky.conf
  sed -i "s/color1 = '#F0C674'/color1 = '#E6A23C'/g" ~/.config/conky/conky.conf
  sed -i "s/color1 = '#D98E04'/color1 = '#E6A23C'/g" ~/.config/conky/conky.conf
fi

# Overrides .desktop con kalita-launch
SETUP_LAUNCHERS="$(dirname "$0")/kalita-setup-launchers.sh"
[ -f "$SETUP_LAUNCHERS" ] && bash "$SETUP_LAUNCHERS"

# Reiniciar componentes visuales
xfwm4 --replace &
sleep 1
pkill -x xfce4-panel; sleep 1; xfce4-panel &
xfdesktop --reload

pkill conky 2>/dev/null || true
sleep 1
conky -c ~/.config/conky/conky.conf &

echo "[OK] Look aplicado."
echo "Si algo no cambia, cierra sesión y vuelve a entrar."
