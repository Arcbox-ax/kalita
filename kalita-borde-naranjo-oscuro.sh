#!/usr/bin/env bash
set -e

NEW_THEME="kAlita-orange-dark"
DEST="$HOME/.themes/$NEW_THEME"
CURRENT_THEME="$(xfconf-query -c xfwm4 -p /general/theme 2>/dev/null || echo Greybird-dark)"

echo "[+] Tema XFWM4 actual: $CURRENT_THEME"

BASE=""

for ruta in \
  "$HOME/.themes/$CURRENT_THEME" \
  "/usr/share/themes/$CURRENT_THEME" \
  "$HOME/.themes/Greybird-dark" \
  "/usr/share/themes/Greybird-dark" \
  "$HOME/.themes/Darkcompact" \
  "/usr/share/themes/Kali-Dark" \
  "/usr/share/themes/Greybird"
do
  if [ -d "$ruta/xfwm4" ]; then
    BASE="$ruta"
    break
  fi
done

if [ -z "$BASE" ]; then
  echo "[ERROR] No encontré un tema XFWM4 base."
  echo "Ejecuta:"
  echo "find /usr/share/themes ~/.themes -type d -name xfwm4 2>/dev/null"
  exit 1
fi

echo "[+] Usando base: $BASE"

mkdir -p "$HOME/.themes"
rm -rf "$DEST"
cp -a "$BASE" "$DEST"

THEMERC="$DEST/xfwm4/themerc"

echo "[+] Ajustando configuración del tema..."

cat >> "$THEMERC" <<'EOF'

# kAlita orange dark tweak
button_spacing=0
button_offset=0
title_vertical_offset_active=0
title_vertical_offset_inactive=0
title_horizontal_offset=4

active_text_color=#E6A23C
inactive_text_color=#777777
active_shadow_color=#1A0D00
inactive_shadow_color=#111111
EOF

echo "[+] Intentando reemplazar colores del tema por naranjo oscuro..."

find "$DEST/xfwm4" -type f \( -iname "*.xpm" -o -iname "*.rc" -o -iname "*.themerc" -o -iname "themerc" \) -print0 | while IFS= read -r -d '' file; do
  sed -i \
    -e 's/#2b2b2b/#4A2A00/gI' \
    -e 's/#202020/#2B1800/gI' \
    -e 's/#333333/#4A2A00/gI' \
    -e 's/#3a3a3a/#5A3400/gI' \
    -e 's/#1f1f1f/#1A0D00/gI' \
    -e 's/#000000/#1A0D00/gI' \
    "$file" || true
done

echo "[+] Aplicando tema nuevo..."
xfconf-query -c xfwm4 -p /general/theme -s "$NEW_THEME"
xfconf-query -c xfwm4 -p /general/title_font -s "Noto Sans Bold 7"
xfconf-query -c xfwm4 -p /general/borderless_maximize -s true

echo "[+] Reiniciando gestor de ventanas..."
xfwm4 --replace &

echo
echo "[OK] Tema aplicado: $NEW_THEME"
echo "Color base: #4A2A00"
echo "Texto/acento: #E6A23C"
