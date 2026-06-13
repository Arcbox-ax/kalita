#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# Enchular Kali XFCE estilo macOS
# By Robinson/Rhuna mode :)
# =========================================================
# Uso recomendado:
#   DPI=75 bash enchular-macos-kali.sh
#
# DPI más sano:
#   DPI=85 bash enchular-macos-kali.sh
# =========================================================

DPI="${DPI:-85}"

if [[ "$EUID" -eq 0 ]]; then
  echo "No ejecutes esto como root. Ejecútalo como tu usuario normal."
  exit 1
fi

echo "[+] Preparando estilo macOS para Kali XFCE..."
echo "[+] DPI elegido: $DPI"

sudo -v

# ---------------------------------------------------------
# 1) Backup básico
# ---------------------------------------------------------
BACKUP_DIR="$HOME/.config/xfce-macos-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "[+] Guardando backup en: $BACKUP_DIR"

for item in "$HOME/.config/xfce4" \
            "$HOME/.config/gtk-3.0" \
            "$HOME/.config/plank" \
            "$HOME/.config/autostart" \
            "$HOME/.config/picom.conf" \
            "$HOME/.gtkrc-2.0"; do
  if [[ -e "$item" ]]; then
    cp -a "$item" "$BACKUP_DIR/" 2>/dev/null || true
  fi
done

# ---------------------------------------------------------
# 2) Paquetes base
# ---------------------------------------------------------
echo "[+] Instalando paquetes necesarios..."

sudo apt update

PKGS=(
  git
  curl
  plank
  picom
  rofi
  arc-theme
  papirus-icon-theme
  fonts-noto-color-emoji
  fonts-jetbrains-mono
  gtk2-engines-murrine
  gtk2-engines-pixbuf
  sassc
  imagemagick
  libglib2.0-dev-bin
)

for pkg in "${PKGS[@]}"; do
  sudo apt install -y "$pkg" || echo "[!] No se pudo instalar $pkg, sigo igual..."
done

# ---------------------------------------------------------
# 3) Descargar WhiteSur GTK, iconos y cursor
# ---------------------------------------------------------
SRC_DIR="$HOME/.local/src/macos-look"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

clone_or_update() {
  local url="$1"
  local dir="$2"

  if [[ -d "$dir/.git" ]]; then
    echo "[+] Actualizando $dir..."
    git -C "$dir" pull --ff-only || true
  else
    echo "[+] Clonando $dir..."
    git clone --depth=1 "$url" "$dir"
  fi
}

clone_or_update "https://github.com/vinceliuice/WhiteSur-gtk-theme.git" "WhiteSur-gtk-theme"
clone_or_update "https://github.com/vinceliuice/WhiteSur-icon-theme.git" "WhiteSur-icon-theme"
clone_or_update "https://github.com/vinceliuice/WhiteSur-cursors.git" "WhiteSur-cursors"

# ---------------------------------------------------------
# 4) Instalar temas
# ---------------------------------------------------------
echo "[+] Instalando tema GTK WhiteSur..."
cd "$SRC_DIR/WhiteSur-gtk-theme"
bash ./install.sh || echo "[!] Falló instalación GTK WhiteSur."

echo "[+] Instalando iconos WhiteSur..."
cd "$SRC_DIR/WhiteSur-icon-theme"
bash ./install.sh || echo "[!] Falló instalación de iconos WhiteSur."

echo "[+] Instalando cursores WhiteSur..."
cd "$SRC_DIR/WhiteSur-cursors"
bash ./install.sh || echo "[!] Falló instalación de cursor WhiteSur."

# ---------------------------------------------------------
# 5) Función segura para xfconf
# ---------------------------------------------------------
set_xfconf() {
  local channel="$1"
  local prop="$2"
  local type="$3"
  local value="$4"

  if xfconf-query -c "$channel" -p "$prop" >/dev/null 2>&1; then
    xfconf-query -c "$channel" -p "$prop" -s "$value" || true
  else
    xfconf-query -c "$channel" -p "$prop" --create -t "$type" -s "$value" || true
  fi
}

# ---------------------------------------------------------
# 6) Detectar nombres reales instalados
# ---------------------------------------------------------
find_first_theme() {
  for base in "$HOME/.themes" "/usr/share/themes"; do
    [[ -d "$base" ]] || continue
    find "$base" -maxdepth 1 -type d -name "WhiteSur*" -printf "%f\n" 2>/dev/null
  done | grep -Ei "dark|Dark" | head -n1 || true
}

find_first_icon() {
  for base in "$HOME/.icons" "$HOME/.local/share/icons" "/usr/share/icons"; do
    [[ -d "$base" ]] || continue
    find "$base" -maxdepth 1 -type d -name "WhiteSur*" -printf "%f\n" 2>/dev/null
  done | grep -Eiv "cursor|cursors" | head -n1 || true
}

find_first_cursor() {
  for base in "$HOME/.icons" "$HOME/.local/share/icons" "/usr/share/icons"; do
    [[ -d "$base" ]] || continue
    find "$base" -maxdepth 1 -type d -iname "*WhiteSur*cursor*" -printf "%f\n" 2>/dev/null
  done | head -n1 || true
}

find_first_xfwm_theme() {
  for base in "$HOME/.themes" "/usr/share/themes"; do
    [[ -d "$base" ]] || continue
    find "$base" -maxdepth 2 -type d -name "xfwm4" -printf "%h\n" 2>/dev/null
  done | xargs -r -n1 basename | grep -Ei "WhiteSur.*dark|WhiteSur.*Dark" | head -n1 || true
}

GTK_THEME="$(find_first_theme)"
ICON_THEME="$(find_first_icon)"
CURSOR_THEME="$(find_first_cursor)"
XFWM_THEME="$(find_first_xfwm_theme)"

GTK_THEME="${GTK_THEME:-WhiteSur-Dark}"
ICON_THEME="${ICON_THEME:-WhiteSur}"
CURSOR_THEME="${CURSOR_THEME:-WhiteSur-cursors}"
XFWM_THEME="${XFWM_THEME:-$GTK_THEME}"

echo "[+] GTK Theme     : $GTK_THEME"
echo "[+] Icon Theme    : $ICON_THEME"
echo "[+] Cursor Theme  : $CURSOR_THEME"
echo "[+] XFWM Theme    : $XFWM_THEME"

# ---------------------------------------------------------
# 7) Aplicar look XFCE
# ---------------------------------------------------------
echo "[+] Aplicando tema en XFCE..."

set_xfconf xsettings /Net/ThemeName string "$GTK_THEME"
set_xfconf xsettings /Net/IconThemeName string "$ICON_THEME"
set_xfconf xsettings /Gtk/CursorThemeName string "$CURSOR_THEME"
set_xfconf xsettings /Gtk/CursorThemeSize int 24

set_xfconf xsettings /Gtk/FontName string "Inter 9"
set_xfconf xsettings /Gtk/MonospaceFontName string "JetBrains Mono 9"
set_xfconf xsettings /Xft/DPI int "$DPI"

set_xfconf xfwm4 /general/theme string "$XFWM_THEME"
set_xfconf xfwm4 /general/button_layout string "CHM|"
set_xfconf xfwm4 /general/title_alignment string "center"

# Panel más delgado
if xfconf-query -c xfce4-panel -l >/dev/null 2>&1; then
  for prop in $(xfconf-query -c xfce4-panel -l | grep -E "/panels/panel-[0-9]+/size$" || true); do
    xfconf-query -c xfce4-panel -p "$prop" -s 26 || true
  done

  for prop in $(xfconf-query -c xfce4-panel -l | grep -E "/panels/panel-[0-9]+/length$" || true); do
    xfconf-query -c xfce4-panel -p "$prop" -s 100 || true
  done
fi

# ---------------------------------------------------------
# 8) Terminal más limpia
# ---------------------------------------------------------
echo "[+] Ajustando terminal XFCE..."

TERMRC="$HOME/.config/xfce4/terminal/terminalrc"
mkdir -p "$(dirname "$TERMRC")"
touch "$TERMRC"

set_terminal_key() {
  local key="$1"
  local value="$2"

  if grep -q "^${key}=" "$TERMRC"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$TERMRC"
  else
    echo "${key}=${value}" >> "$TERMRC"
  fi
}

set_terminal_key "FontName" "JetBrains Mono 9"
set_terminal_key "MiscMenubarDefault" "FALSE"
set_terminal_key "MiscToolbarDefault" "FALSE"
set_terminal_key "MiscBordersDefault" "TRUE"
set_terminal_key "ColorCursorUseDefault" "FALSE"
set_terminal_key "ColorCursor" "#ffffff"

# ---------------------------------------------------------
# 9) Picom: sombras/transparencia suave
# ---------------------------------------------------------
echo "[+] Configurando Picom..."

cat > "$HOME/.config/picom.conf" <<'PICOME'
backend = "xrender";
vsync = true;

shadow = true;
shadow-radius = 12;
shadow-offset-x = -5;
shadow-offset-y = -5;
shadow-opacity = 0.28;

fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;

inactive-opacity = 0.97;
active-opacity = 1.0;
frame-opacity = 1.0;

mark-wmwin-focused = true;
mark-ovredir-focused = true;
detect-rounded-corners = true;
detect-client-opacity = true;
refresh-rate = 0;

shadow-exclude = [
  "name = 'Notification'",
  "class_g = 'Xfce4-panel'",
  "class_g = 'Plank'",
  "class_g = 'Rofi'"
];
PICOME

mkdir -p "$HOME/.config/autostart"

cat > "$HOME/.config/autostart/picom.desktop" <<'PICOMD'
[Desktop Entry]
Type=Application
Name=Picom
Comment=Compositor con sombras suaves
Exec=sh -c 'sleep 1; picom --config "$HOME/.config/picom.conf" --daemon'
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
PICOMD

# ---------------------------------------------------------
# 10) Plank como Dock inferior
# ---------------------------------------------------------
echo "[+] Configurando Plank Dock..."

cat > "$HOME/.config/autostart/plank.desktop" <<'PLANKD'
[Desktop Entry]
Type=Application
Name=Plank
Comment=Dock estilo macOS
Exec=sh -c 'sleep 2; plank'
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
PLANKD

mkdir -p "$HOME/.config/plank/dock1"

cat > "$HOME/.config/plank/dock1/settings" <<'PLANKS'
[PlankDockPreferences]
CurrentWorkspaceOnly=false
IconSize=44
HideMode=1
UnhideDelay=0
HideDelay=0
Monitor=
DockItems=
Position=3
Offset=0
Theme=Transparent
Alignment=3
ItemsAlignment=3
LockItems=false
PressureReveal=false
PinnedOnly=false
AutoPinning=true
ShowDockItem=false
ZoomEnabled=true
ZoomPercent=120
PLANKS

# ---------------------------------------------------------
# 11) Wallpaper simple estilo macOS oscuro
# ---------------------------------------------------------
echo "[+] Creando wallpaper simple..."

mkdir -p "$HOME/Pictures/Wallpapers"
WALL="$HOME/Pictures/Wallpapers/kali-macos-soft.png"

if command -v magick >/dev/null 2>&1; then
  magick -size 1366x768 gradient:'#111827-#5b21b6' "$WALL" || true
elif command -v convert >/dev/null 2>&1; then
  convert -size 1366x768 gradient:'#111827-#5b21b6' "$WALL" || true
fi

if [[ -f "$WALL" ]]; then
  if xfconf-query -c xfce4-desktop -l >/dev/null 2>&1; then
    for prop in $(xfconf-query -c xfce4-desktop -l | grep "last-image$" || true); do
      xfconf-query -c xfce4-desktop -p "$prop" -s "$WALL" || true
    done
  fi
fi

# ---------------------------------------------------------
# 12) Reiniciar componentes visuales
# ---------------------------------------------------------
echo "[+] Reiniciando panel/compositor/dock..."

xfce4-panel -r >/dev/null 2>&1 || true

pkill picom >/dev/null 2>&1 || true
picom --config "$HOME/.config/picom.conf" --daemon >/dev/null 2>&1 || true

pkill plank >/dev/null 2>&1 || true
nohup plank >/dev/null 2>&1 &

echo
echo "========================================================="
echo " Listo. Kali quedó más estilo macOS."
echo " Backup guardado en:"
echo " $BACKUP_DIR"
echo
echo " Recomendado: cerrar sesión y volver a entrar."
echo " Para cambiar el dock: Ctrl + clic derecho sobre Plank."
echo "========================================================="
