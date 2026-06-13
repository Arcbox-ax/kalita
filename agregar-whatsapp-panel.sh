#!/bin/bash
set -euo pipefail

# Agrega un lanzador de WhatsApp Web (Firefox) al panel XFCE

PANEL="panel-1"
NEW_ID=32
ICON="whatsapp"
LAUNCHER_DIR="$HOME/.config/xfce4/panel/launcher-${NEW_ID}"
APP_DESKTOP="$HOME/.local/share/applications/whatsapp-web-firefox.desktop"
TIMESTAMP=$(date +%s%N | cut -c1-17)

echo "[+] Actualizando .desktop de WhatsApp Web (Firefox)..."
mkdir -p "$(dirname "$APP_DESKTOP")"
cat > "$APP_DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=WhatsApp Web
Comment=WhatsApp Web en Firefox
Exec=firefox --new-window "https://web.whatsapp.com/"
Icon=${ICON}
Terminal=false
Categories=Network;InstantMessaging;
StartupNotify=true
StartupWMClass=Firefox
EOF

echo "[+] Creando directorio del lanzador en el panel (ID ${NEW_ID})..."
mkdir -p "$LAUNCHER_DIR"
cat > "$LAUNCHER_DIR/${TIMESTAMP}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=WhatsApp Web
Comment=WhatsApp Web en Firefox
Exec=firefox --new-window "https://web.whatsapp.com/"
Icon=${ICON}
Terminal=false
Categories=Network;InstantMessaging;
StartupNotify=true
StartupWMClass=Firefox
X-XFCE-Source=file://${APP_DESKTOP}
EOF

echo "[+] Registrando plugin ${NEW_ID} como launcher en xfconf..."
xfconf-query -c xfce4-panel -p /plugins/plugin-${NEW_ID} \
  -n -t string -s launcher 2>/dev/null || \
xfconf-query -c xfce4-panel -p /plugins/plugin-${NEW_ID} \
  -s launcher

echo "[+] Añadiendo plugin ${NEW_ID} al array de plugins del panel..."
# IDs actuales: 1 12 3 7 6 5 30 8 31 20 14 19 22  → insertar 32 después de 30
xfconf-query -c xfce4-panel -p /panels/${PANEL}/plugin-ids \
  -t int -t int -t int -t int -t int -t int -t int -t int \
  -t int -t int -t int -t int -t int -t int \
  -s 1 -s 12 -s 3 -s 7 -s 6 -s 5 -s 30 -s ${NEW_ID} \
  -s 8 -s 31 -s 20 -s 14 -s 19 -s 22

echo "[+] Recargando panel XFCE..."
xfce4-panel -r &
sleep 1

echo "[OK] Lanzador de WhatsApp Web agregado al panel (posición después del launcher-30)."
echo "     Si quieres reposicionarlo, haz clic derecho en el panel → Configurar panel."
