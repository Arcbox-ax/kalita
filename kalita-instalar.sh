#!/usr/bin/env bash
# kalita-instalar.sh — Instalador completo del entorno kAlita en Kali Linux XFCE
# Aplica todas las preferencias, lanzadores, scripts y tema de Robinson Cáceres
# Uso: bash kalita-instalar.sh
set -euo pipefail

KALITA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$HOME/scripts"
ok()  { echo "[OK] $*"; }
inf() { echo "[+] $*"; }
warn(){ echo "[!] $*"; }

echo ""
echo "╔══════════════════════════════════════╗"
echo "║      kAlita Installer v1.0           ║"
echo "║   Kali Linux XFCE — Robinson C.      ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. DEPENDENCIAS ─────────────────────────────────────────────────────────
inf "Verificando dependencias..."
PKGS=()
for pkg in xdotool wmctrl icoutils python3-pil flatpak; do
  dpkg -l "$pkg" &>/dev/null || PKGS+=("$pkg")
done
if [ ${#PKGS[@]} -gt 0 ]; then
  inf "Instalando: ${PKGS[*]}"
  sudo apt-get install -y "${PKGS[@]}" 2>/dev/null
fi
ok "Dependencias OK"

# ── 2. TEMA XFCE ────────────────────────────────────────────────────────────
inf "Aplicando tema XFCE (Arc-Dark / Flat-Remix-Orange-Light / kAlita-orange-dark)..."

_xfset() { xfconf-query -c "$1" -p "$2" -n -t "$3" -s "$4" 2>/dev/null || \
            xfconf-query -c "$1" -p "$2" -s "$4" 2>/dev/null || true; }

_xfset xsettings /Net/ThemeName          string "Arc-Dark"
_xfset xsettings /Net/IconThemeName      string "Flat-Remix-Orange-Light"
_xfset xsettings /Gtk/FontName           string "Noto Sans 8"
_xfset xsettings /Gtk/CursorThemeName    string "Adwaita"
_xfset xfwm4     /general/theme          string "kAlita-orange-dark"
_xfset xfwm4     /general/title_font     string "Noto Sans Bold 8"
_xfset xfwm4     /general/button_layout  string "CHM|"

# Fondo de pantalla (Alita — copia local en assets/)
WALLPAPER="$KALITA_DIR/assets/wallpaper.jpg"
if [ ! -f "$WALLPAPER" ]; then
  warn "assets/wallpaper.jpg no encontrado, saltando fondo"
else
  # Copiar a ubicación estable para que XFCE siempre lo encuentre
  cp "$WALLPAPER" "$HOME/.local/share/backgrounds/kalita-wallpaper.jpg" 2>/dev/null || \
    { mkdir -p "$HOME/.local/share/backgrounds" && cp "$WALLPAPER" "$HOME/.local/share/backgrounds/kalita-wallpaper.jpg"; }
  WP="$HOME/.local/share/backgrounds/kalita-wallpaper.jpg"
  # Aplicar en todos los tipos de monitor conocidos (eDP-1, rdp0, VNC-0, HDMI-2, monitor0-4)
  for MON in eDP-1 rdp0 VNC-0 HDMI-1 HDMI-2 0 1 2; do
    BASE="/backdrop/screen0/monitor${MON}"
    xfconf-query -c xfce4-desktop -p "${BASE}/workspace0/last-image" \
      -n -t string -s "$WP" 2>/dev/null || \
    xfconf-query -c xfce4-desktop -p "${BASE}/workspace0/last-image" \
      -s "$WP" 2>/dev/null || true
    xfconf-query -c xfce4-desktop -p "${BASE}/workspace0/image-style" \
      -n -t int -s 5 2>/dev/null || \
    xfconf-query -c xfce4-desktop -p "${BASE}/workspace0/image-style" \
      -s 5 2>/dev/null || true
    # Compatibilidad con config antigua (image-path)
    xfconf-query -c xfce4-desktop -p "${BASE}/image-path" \
      -s "$WP" 2>/dev/null || true
    xfconf-query -c xfce4-desktop -p "${BASE}/last-image" \
      -s "$WP" 2>/dev/null || true
  done
  xfdesktop --reload 2>/dev/null || true
fi
ok "Tema XFCE aplicado"

# ── 3. TEMA GTK CSS (borde naranja kAlita) ──────────────────────────────────
inf "Aplicando tema xfwm4 kAlita-orange-dark..."
if [ -f "$KALITA_DIR/kalita-borde-naranjo-oscuro.sh" ]; then
  bash "$KALITA_DIR/kalita-borde-naranjo-oscuro.sh"
  ok "Borde naranja aplicado"
else
  warn "kalita-borde-naranjo-oscuro.sh no encontrado, saltando"
fi

# ── 4. TERMINAL ──────────────────────────────────────────────────────────────
inf "Configurando terminal XFCE..."
if [ -f "$KALITA_DIR/pulir-darkcompact-kali.sh" ]; then
  bash "$KALITA_DIR/pulir-darkcompact-kali.sh"
  ok "Terminal configurada"
fi

# ── 5. ÍCONOS CUSTOM ─────────────────────────────────────────────────────────
inf "Instalando íconos custom..."
mkdir -p ~/.local/share/icons/hicolor/{48x48,64x64}/apps/

# cMUD icon — extraer del .exe si no existe
CMUD_ICON="$HOME/.local/share/icons/hicolor/48x48/apps/cmud.png"
CMUD_EXE="$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/C_MUD/drive_c/Program Files (x86)/CMUD/cMUD.exe"
if [ ! -f "$CMUD_ICON" ] && [ -f "$CMUD_EXE" ]; then
  TMP=$(mktemp -d)
  wrestool -x -t 14 "$CMUD_EXE" -o "$TMP/" 2>/dev/null || true
  ICO=$(ls "$TMP/"*MAINICON*.ico 2>/dev/null | head -1)
  if [ -n "$ICO" ]; then
    icotool -x -i 8 "$ICO" -o "$TMP/" 2>/dev/null || \
    icotool -x -i 6 "$ICO" -o "$TMP/" 2>/dev/null || true
    PNG=$(ls "$TMP/"*.png 2>/dev/null | sort -t x -k2 -rn | head -1)
    [ -n "$PNG" ] && cp "$PNG" "$CMUD_ICON"
  fi
  rm -rf "$TMP"
fi
[ -f "$CMUD_ICON" ] && convert "$CMUD_ICON" -resize 64x64 \
  "$HOME/.local/share/icons/hicolor/64x64/apps/cmud.png" 2>/dev/null || true

# Mudlet icon — desde squashfs del AppImage
MUDLET_SFS="$HOME/Applications/Mudlet/squashfs-root"
if [ -f "$MUDLET_SFS/mudlet.png" ]; then
  mkdir -p ~/.local/share/icons/hicolor/scalable/apps
  cp "$MUDLET_SFS/mudlet.png" ~/.local/share/icons/hicolor/48x48/apps/mudlet.png
  [ -f "$MUDLET_SFS/mudlet.svg" ] && \
    cp "$MUDLET_SFS/mudlet.svg" ~/.local/share/icons/hicolor/scalable/apps/mudlet.svg
fi

gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor/ 2>/dev/null || true
ok "Íconos instalados"

# ── 6. SCRIPTS HELPERS ───────────────────────────────────────────────────────
inf "Instalando scripts helpers..."
mkdir -p ~/.local/bin

# claude-desktop-rdp (fix RDP para Electron)
cat > ~/.local/bin/claude-desktop-rdp << 'EOF'
#!/usr/bin/env bash
LIBGL_ALWAYS_SOFTWARE=1 \
GALLIUM_DRIVER=llvmpipe \
XRDP_SESSION="" \
/usr/bin/claude-desktop "$@"
EOF
chmod +x ~/.local/bin/claude-desktop-rdp

# Copiar scripts de ~/scripts si existen
mkdir -p "$SCRIPTS_DIR"
for s in cmud.sh cmud-fix-window.sh dock_xfce_backup.sh; do
  src="$SCRIPTS_DIR/$s"
  [ -f "$src" ] && chmod +x "$src" && ok "  $s OK"
done
ok "Scripts helpers OK"

# ── 7. LANZADORES .DESKTOP ───────────────────────────────────────────────────
inf "Instalando lanzadores .desktop..."
mkdir -p ~/.local/share/applications

# Claude Desktop (wrapper RDP)
cat > ~/.local/share/applications/claude-desktop.desktop << 'EOF'
[Desktop Entry]
Name=Claude
Exec=/home/rcaceres/.local/bin/claude-desktop-rdp %u
Icon=claude-desktop
Type=Application
Terminal=false
Categories=Office;Utility;
MimeType=x-scheme-handler/claude;
StartupWMClass=claude
EOF

# BambuStudio (Flatpak, ícono absoluto por tema)
cat > ~/.local/share/applications/com.bambulab.BambuStudio.desktop << 'EOF'
[Desktop Entry]
Name=BambuStudio
GenericName=3D Printing Software
Icon=/var/lib/flatpak/exports/share/icons/hicolor/128x128/apps/com.bambulab.BambuStudio.png
Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=entrypoint --file-forwarding com.bambulab.BambuStudio @@u %U @@
Terminal=false
Type=Application
Categories=Graphics;3DGraphics;Engineering;
StartupWMClass=bambu-studio
X-Flatpak=com.bambulab.BambuStudio
EOF

# cMUD (Bottles via script directo)
cat > ~/.local/share/applications/com.usebottles.bottles.App_82ca22368dd2339eb4d71f48594b32296c6e76fd.desktop << 'EOF'
[Desktop Entry]
Name=cMUD
Exec=/home/rcaceres/scripts/cmud.sh
Icon=cmud
Type=Application
Terminal=false
Categories=Application;
Comment=Launch cMUD using Bottles.
StartupWMClass=steam_proton
TryExec=/var/lib/flatpak/exports/bin/com.usebottles.bottles
X-Flatpak=com.usebottles.bottles
EOF

# WhatsApp Web (Firefox perfil dedicado)
cat > ~/.local/share/applications/whatsapp-web-firefox.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=WhatsApp
Comment=WhatsApp Web en Firefox
Exec=env MOZ_DISABLE_RDD_SANDBOX=1 firefox --no-remote --class=WhatsApp --profile /home/rcaceres/.mozilla/firefox/whatsapp-web https://web.whatsapp.com/
Icon=/usr/share/icons/Papirus/48x48/apps/whatsapp.svg
Terminal=false
Categories=Network;InstantMessaging;
StartupWMClass=WhatsApp
EOF

# cMUD (lanzador directo vía cmud.sh)
cat > ~/.local/share/applications/cMUD.desktop << 'EOF'
[Desktop Entry]
Name=cMUD
Comment=Cliente MUD
Exec=/home/rcaceres/scripts/kalita-launch cMUD steam_proton bash /home/rcaceres/scripts/cmud.sh
Icon=/home/rcaceres/Imágenes/cmud.png
Terminal=false
Type=Application
Categories=Game;
StartupWMClass=steam_proton
X-KalitaLaunch=true
EOF

# Mudlet (AppImage)
cat > ~/.local/share/applications/mudlet.desktop << 'EOF'
[Desktop Entry]
Name=Mudlet
Comment=MUD Client
Exec=/home/rcaceres/scripts/kalita-launch mudlet Mudlet /home/rcaceres/Descargas/Mudlet-4.20.1.AppImage
Icon=mudlet
Terminal=false
Type=Application
Categories=Network;Game;
StartupWMClass=Mudlet
X-KalitaLaunch=true
EOF

update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
ok "Lanzadores instalados"

# ── 8. PERFIL FIREFOX WHATSAPP ───────────────────────────────────────────────
inf "Configurando perfil Firefox para WhatsApp..."
WA_PROFILE="$HOME/.mozilla/firefox/whatsapp-web"
if [ ! -d "$WA_PROFILE" ]; then
  firefox --CreateProfile "whatsapp-web $WA_PROFILE" 2>/dev/null || true
fi
mkdir -p "$WA_PROFILE/chrome"
cat > "$WA_PROFILE/chrome/userChrome.css" << 'EOF'
#TabsToolbar        { visibility: collapse !important; }
#PersonalToolbar    { visibility: collapse !important; }
#toolbar-menubar    { visibility: collapse !important; }
EOF
cat > "$WA_PROFILE/user.js" << 'EOF'
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
EOF
ok "Perfil WhatsApp configurado"

# ── 9. DOCK (docklike) ───────────────────────────────────────────────────────
inf "Configurando dock (docklike)..."
cat > ~/.config/xfce4/panel/docklike-31.rc << 'EOF'
[user]
pinned=com.bambulab.BambuStudio;filezilla;com.usebottles.bottles.App_82ca22368dd2339eb4d71f48594b32296c6e76fd;whatsapp-web-firefox;xfce4-screenshooter;claude-desktop;firefox-esr;qterminal;google-chrome;org.pulseaudio.pavucontrol;Z-Library;com.sublimehq.SublimeText;calibre-gui;com.discordapp.Discord;cMUD;mudlet;
indicatorColor=rgb(230,162,60)
inactiveColor=rgb(100,100,100)
indicatorColorFromTheme=false
indicatorStyle=0
inactiveIndicatorStyle=0
indicatorOrientation=1
EOF
ok "Dock configurado"

# ── 10. PLANK DOCK ───────────────────────────────────────────────────────────
inf "Configurando Plank dock..."
mkdir -p "$HOME/.config/plank/dock1"
cat > "$HOME/.config/plank/dock1/settings" << 'EOF'
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
EOF
ok "Plank configurado"

# ── 11. PICOM (compositor) ───────────────────────────────────────────────────
inf "Instalando configuración de Picom..."
dpkg -l picom &>/dev/null || sudo apt-get install -y picom 2>/dev/null
mkdir -p "$HOME/.config"
cat > "$HOME/.config/picom.conf" << 'EOF'
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

shadow-exclude = [
  "name = 'Notification'",
  "class_g = 'Xfce4-panel'",
  "class_g = 'Plank'",
  "class_g = 'Rofi'"
];
EOF
ok "Picom configurado"

# ── 12. CONKY WIDGET ─────────────────────────────────────────────────────────
inf "Instalando Conky kAlita Monitor..."
dpkg -l conky-all &>/dev/null || sudo apt-get install -y conky-all 2>/dev/null
mkdir -p "$HOME/.config/conky"
cat > "$HOME/.config/conky/conky.conf" << 'EOF'
conky.config = {
    alignment = 'top_right',
    background = true,
    update_interval = 1,
    double_buffer = true,
    no_buffers = true,

    use_xft = true,
    font = 'DejaVu Sans Mono:size=9',
    override_utf8_locale = true,

    own_window = true,
    own_window_class = 'Conky',
    own_window_type = 'desktop',
    own_window_transparent = true,
    own_window_argb_visual = true,
    own_window_argb_value = 70,
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',

    minimum_width = 290,
    maximum_width = 290,
    gap_x = 25,
    gap_y = 45,

    draw_shades = false,
    draw_outline = false,
    draw_borders = false,

    default_color = 'white',
    color1 = '#E6A23C',
    color2 = 'lightgrey',
    color3 = 'orange',
};

conky.text = [[
${color1}${font DejaVu Sans Mono:bold:size=12}kAlita Monitor${font}${color}
${hr}

${color1}Sistema:${color}
Host: $nodename
Kernel: $kernel
Uptime: $uptime

${color1}CPU:${color} ${cpu cpu0}%
${cpubar cpu0 8}
${cpugraph cpu0 25,270}

${color1}RAM:${color} $mem / $memmax - $memperc%
${membar 8}

${color1}Swap:${color} $swap / $swapmax - $swapperc%
${swapbar 8}

${color1}Disco /:${color}
${fs_used /} / ${fs_size /} - ${fs_used_perc /}%
${fs_bar 8 /}

${color1}Red wlan0:${color}
IP: ${addr wlan0}
Down: ${downspeedf wlan0} KiB/s
Up:   ${upspeedf wlan0} KiB/s
${downspeedgraph wlan0 22,130} ${upspeedgraph wlan0 22,130}

${color1}Procesos:${color}
Total: $processes
Activos: $running_processes

${color1}Top CPU:${color}
${top name 1} ${alignr}${top cpu 1}%
${top name 2} ${alignr}${top cpu 2}%
${top name 3} ${alignr}${top cpu 3}%

${color1}Top RAM:${color}
${top_mem name 1} ${alignr}${top_mem mem_res 1}
${top_mem name 2} ${alignr}${top_mem mem_res 2}
${top_mem name 3} ${alignr}${top_mem mem_res 3}
]]
EOF
ok "Conky configurado"

# ── 13. AUTOSTART ────────────────────────────────────────────────────────────
inf "Configurando autostart..."
mkdir -p "$HOME/.config/autostart"

cat > "$HOME/.config/autostart/conky-kalita.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Conky kAlita Monitor
Comment=Monitor de CPU, RAM, red y disco en el escritorio
Exec=sh -c "sleep 5 && conky -c /home/rcaceres/.config/conky/conky.conf"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Terminal=false
EOF

cat > "$HOME/.config/autostart/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Comment=Dock estilo macOS
Exec=sh -c 'sleep 2; plank'
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
EOF

cat > "$HOME/.config/autostart/xfce4-panel.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=XFCE Panel
Exec=sh -c 'sleep 4 && pgrep -x xfce4-panel > /dev/null || xfce4-panel'
Hidden=false
X-GNOME-Autostart-enabled=true
OnlyShowIn=XFCE;
EOF

cat > "$HOME/.config/autostart/picom.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Picom Compositor
Exec=picom --config /home/rcaceres/.config/picom.conf -b
Hidden=false
X-GNOME-Autostart-enabled=true
OnlyShowIn=XFCE;
EOF
ok "Autostart configurado"

# ── 14. QT THEMING ───────────────────────────────────────────────────────────
inf "Configurando tema Qt5..."
mkdir -p "$HOME/.config/qt5ct"
cat > "$HOME/.config/qt5ct/qt5ct.conf" << 'EOF'
[Appearance]
custom_palette=true
icon_theme=Flat-Remix-Blue-Dark
color_scheme_path=/usr/share/qt5ct/colors/Kali-Dark.conf
standard_dialogs=gtk3
style=Fusion

[Interface]
stylesheets=/usr/share/qt5ct/qss/fusion-simple-scrollbar.qss
EOF
# Variable de entorno Qt5 para que use qt5ct
if ! grep -q "QT_QPA_PLATFORMTHEME" "$HOME/.zshrc" 2>/dev/null; then
  echo 'export QT_QPA_PLATFORMTHEME=qt5ct' >> "$HOME/.zshrc"
fi
ok "Qt5 configurado"

# ── 15. MIME TYPES Y APPS POR DEFECTO ────────────────────────────────────────
inf "Configurando tipos MIME y aplicaciones por defecto..."
mkdir -p "$HOME/.config"
cat > "$HOME/.config/mimeapps.list" << 'EOF'
[Default Applications]
x-scheme-handler/claude-cli=claude-code-url-handler.desktop
x-scheme-handler/telnet=mudlet.desktop
x-scheme-handler/telnets=mudlet.desktop
application/vnd.comicbook-rar=engrampa.desktop

[Added Associations]
text/markdown=com.sublimehq.SublimeText.desktop;
application/xml=com.sublimehq.SublimeText.desktop;
application/x-shellscript=com.sublimehq.SublimeText.desktop;
text/html=firefox-esr.desktop;
application/vnd.debian.binary-package=gdebi.desktop;
application/epub+zip=calibre-gui.desktop;
text/plain=com.sublimehq.SublimeText.desktop;
application/vnd.comicbook-rar=engrampa.desktop;
EOF
ok "MIME types configurados"

# ── 16. VNC SYSTEMD SERVICE ──────────────────────────────────────────────────
inf "Instalando servicio systemd VNC..."
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/vncserver@.service" << 'EOF'
[Unit]
Description=TigerVNC Server en display :%i
After=network.target

[Service]
Type=forking
ExecStartPre=-/usr/bin/vncserver -kill %i
ExecStart=/usr/bin/vncserver %i -localhost yes -geometry 1600x900 -depth 24
ExecStop=/usr/bin/vncserver -kill %i

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable vncserver@:1.service 2>/dev/null || true
sudo loginctl enable-linger "$USER" 2>/dev/null || true
ok "Servicio VNC configurado"

# ── 17. HOSTNAME Y HOSTS ─────────────────────────────────────────────────────
inf "Verificando hostname kAlita..."
if ! grep -q "127.0.1.1.*kAlita" /etc/hosts 2>/dev/null; then
  echo "127.0.1.1	kAlita" | sudo tee -a /etc/hosts > /dev/null
  ok "Hostname kAlita agregado a /etc/hosts"
else
  ok "Hostname kAlita ya en /etc/hosts"
fi
# Hostname real del sistema
if [ "$(hostname)" != "kAlita" ]; then
  sudo hostnamectl set-hostname kAlita 2>/dev/null || true
fi

# ── 18. ALIAS SHELL ──────────────────────────────────────────────────────────
inf "Configurando aliases en .zshrc..."
for RCFILE in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$RCFILE" ] || continue
  grep -q "alias cmud=" "$RCFILE" || \
    echo "alias cmud='bash ~/scripts/cmud.sh'" >> "$RCFILE"
  grep -q "QT_QPA_PLATFORMTHEME" "$RCFILE" || \
    echo 'export QT_QPA_PLATFORMTHEME=qt5ct' >> "$RCFILE"
done
ok "Aliases configurados"

# ── 19. GRUB BACKGROUND ─────────────────────────────────────────────────────
inf "Instalando fondo de GRUB (alita.png)..."
GRUB_IMG="$KALITA_DIR/assets/grub-background.png"
if [ -f "$GRUB_IMG" ]; then
  sudo mkdir -p /boot/grub/images
  sudo cp "$GRUB_IMG" /boot/grub/images/alita.png
  # Asegurar que /etc/default/grub tenga la config correcta
  if ! grep -q "GRUB_BACKGROUND" /etc/default/grub 2>/dev/null; then
    echo 'GRUB_BACKGROUND="/boot/grub/images/alita.png"' | sudo tee -a /etc/default/grub > /dev/null
  else
    sudo sed -i 's|^GRUB_BACKGROUND=.*|GRUB_BACKGROUND="/boot/grub/images/alita.png"|' /etc/default/grub
  fi
  if ! grep -q "GRUB_GFXMODE" /etc/default/grub 2>/dev/null; then
    echo 'GRUB_GFXMODE=1366x768' | sudo tee -a /etc/default/grub > /dev/null
    echo 'GRUB_GFXPAYLOAD_LINUX=keep' | sudo tee -a /etc/default/grub > /dev/null
  fi
  sudo update-grub 2>/dev/null && ok "GRUB actualizado con alita.png" || warn "update-grub falló, fondo igual copiado"
else
  warn "assets/grub-background.png no encontrado, saltando GRUB"
fi

# ── 20. SESIÓN ÚNICA (VNC + RDP + local → mismo escritorio) ─────────────────
inf "Configurando sesión única (VNC :1 ← RDP ← local)..."

# xstartup VNC con latam + compositing desactivado (mejor rendimiento VNC)
mkdir -p "$HOME/.vnc"
cat > "$HOME/.vnc/xstartup" << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export DISPLAY=:1

[ -r "$HOME/.Xresources" ] && xrdb "$HOME/.Xresources"

export XKL_XMODMAP_DISABLE=1
export XDG_SESSION_TYPE=x11
export DESKTOP_SESSION=xfce
export XDG_CURRENT_DESKTOP=XFCE

setxkbmap -display :1 -layout latam

# Sin compositing en VNC para evitar conflicto con picom/xcompmgr
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true

exec startxfce4
EOF
chmod +x "$HOME/.vnc/xstartup"

# xrdp → conectar como proxy al VNC :1 (sesión maestra)
if [ -f /etc/xrdp/xrdp.ini ]; then
  # Quitar config anterior y agregar sección Xvnc-kalita
  sudo sed -i '/^autorun=Xvnc-kalita/d' /etc/xrdp/xrdp.ini
  sudo sed -i '/^\[Xvnc-kalita\]/,/^$/d' /etc/xrdp/xrdp.ini
  # autorun en [Globals]
  if ! grep -q "autorun=Xvnc-kalita" /etc/xrdp/xrdp.ini; then
    sudo sed -i '/^ini_version=/a autorun=Xvnc-kalita' /etc/xrdp/xrdp.ini
  fi
  sudo tee -a /etc/xrdp/xrdp.ini > /dev/null << 'EOF'

[Xvnc-kalita]
name=Kalita Sesion Unica
lib=libvnc.so
ip=127.0.0.1
port=5901
username=na
password=ask
EOF
  sudo systemctl restart xrdp xrdp-sesman 2>/dev/null || true
  ok "xrdp configurado como proxy a VNC :1"
else
  warn "xrdp no instalado, saltando config xrdp"
fi

# Script acceso local al escritorio compartido
cat > "$SCRIPTS_DIR/conectar-vnc-local.sh" << 'EOF'
#!/usr/bin/env bash
exec vncviewer localhost:5901
EOF
chmod +x "$SCRIPTS_DIR/conectar-vnc-local.sh"

# Reiniciar VNC si está corriendo
if systemctl --user is-active vncserver@:1.service &>/dev/null; then
  systemctl --user restart vncserver@:1.service
  ok "VNC :1 reiniciado"
else
  warn "VNC no está activo — inicia con: systemctl --user start vncserver@:1.service"
fi

# ── 21. BACKUP INICIAL ───────────────────────────────────────────────────────
inf "Creando backup inicial del dock..."
[ -f "$SCRIPTS_DIR/dock_xfce_backup.sh" ] && \
  bash "$SCRIPTS_DIR/dock_xfce_backup.sh" backup 2>/dev/null || true

# ── 22. SSH REVERSO ──────────────────────────────────────────────────────────
inf "Configurando túnel SSH reverso (petria.rivendel.org)..."
SSH_REVERSO="$SCRIPTS_DIR/instalar-ssh-reverso.sh"
if [ -f "$SSH_REVERSO" ]; then
  bash "$SSH_REVERSO"
else
  warn "instalar-ssh-reverso.sh no encontrado en $SCRIPTS_DIR, saltando"
fi

# ── 23. KALITA-LAUNCH — LAUNCHER INTELIGENTE ────────────────────────────────
inf "Instalando kalita-launch..."
mkdir -p "$SCRIPTS_DIR"
cat > "$SCRIPTS_DIR/kalita-launch" <<'LAUNCH_EOF'
#!/usr/bin/env bash
# kalita-launch — launcher inteligente para docklike
#
# Soluciona apps atascadas en otras sesiones RDP/VNC:
#   - Click simple: si el proceso existe pero NO hay ventana en este display
#                   → mata el proceso, limpia locks y relanza
#   - Doble click (< 800ms): fuerza kill + relaunch siempre
#
# Uso en .desktop: Exec=kalita-launch APP_ID WM_CLASS COMANDO...

APP_ID="${1:-}"
WM_CLASS="${2:-}"
shift 2
CMD=("$@")

if [ -z "$APP_ID" ] || [[ "${APP_ID}" == "-h" || "${APP_ID}" == "--help" ]]; then
    cat >&2 <<'USO'
Uso: kalita-launch APP_ID WM_CLASS COMANDO [ARGS...]

  APP_ID    Identificador único (ej: com.bambulab.BambuStudio)
  WM_CLASS  Clase de ventana para detectar si está abierta (ej: bambu-studio)
  COMANDO   Comando a ejecutar (ej: flatpak run com.bambulab.BambuStudio)

Comportamiento:
  - Click simple:   Si el proceso existe pero no hay ventana en este display
                    → mata el proceso, limpia locks y relanza (app atascada en
                    otra sesión RDP/VNC)
  - Doble click:    Fuerza kill + relaunch siempre (< 800ms entre clics)
  - Sin proceso:    Lanza directamente

USO
    exit 1
fi

# Nombre de proceso: para flatpak usar el WM_CLASS, sino el binario
if [[ "${CMD[0]:-}" == "flatpak" || "${CMD[0]:-}" == "/usr/bin/flatpak" ]]; then
    PROC_PAT="$WM_CLASS"
else
    PROC_PAT="${CMD[0]##*/}"
fi

# ── Detección doble click ────────────────────────────────────────────────────
STAMP="/tmp/kalita-launch-${APP_ID//[^a-zA-Z0-9]/_}"
NOW=$(date +%s%3N)
FORCE=false

if [ -f "$STAMP" ]; then
    LAST=$(cat "$STAMP" 2>/dev/null || echo 0)
    (( (NOW - LAST) < 800 )) && FORCE=true
fi
echo "$NOW" > "$STAMP"

# ── Limpiar instancia atascada ───────────────────────────────────────────────
_kill_and_clean() {
    echo "[kalita-launch] Matando instancia atascada: $APP_ID"
    pkill -f "$PROC_PAT" 2>/dev/null || true
    sleep 0.8
    find ~/.var/app -name "*.lock" 2>/dev/null | xargs rm -f 2>/dev/null || true
    find /tmp -name "*${PROC_PAT}*.lock" -user "$USER" -delete 2>/dev/null || true
    find ~/.config -name "*.lock" -path "*${APP_ID}*" -delete 2>/dev/null || true
}

# ── Detección de app atascada en otra sesión ─────────────────────────────────
_is_running() {
    # Excluir el PID del script actual (bash tiene PROC_PAT en sus args)
    pgrep -f "$PROC_PAT" 2>/dev/null | grep -vxF "$$" | grep -vxF "$PPID" | grep -q .
}

_has_window() {
    xdotool search --classname "$WM_CLASS" > /dev/null 2>&1 && return 0
    wmctrl -l 2>/dev/null | grep -qi "$WM_CLASS" && return 0
    return 1
}

_focus_window() {
    local active
    active=$(xdotool getactivewindow 2>/dev/null || echo 0)
    local -a wids
    mapfile -t wids < <(xdotool search --classname "$WM_CLASS" 2>/dev/null)
    if [ ${#wids[@]} -gt 0 ]; then
        for wid in "${wids[@]}"; do
            if [ "$active" = "$wid" ]; then
                for w in "${wids[@]}"; do
                    xdotool windowminimize "$w" 2>/dev/null || true
                done
                return 0
            fi
        done
        xdotool windowactivate --sync "${wids[0]}" 2>/dev/null || true
        return 0
    fi
    wmctrl -x -a "$WM_CLASS" 2>/dev/null || true
}

# ── Decisión ─────────────────────────────────────────────────────────────────
if _is_running; then
    if [[ "$FORCE" == "true" ]] || ! _has_window; then
        _kill_and_clean
    else
        _focus_window
        exit 0
    fi
fi

exec "${CMD[@]}"
LAUNCH_EOF
chmod +x "$SCRIPTS_DIR/kalita-launch"
ok "kalita-launch instalado en $SCRIPTS_DIR/kalita-launch"

# ── 24. SETUP LAUNCHERS — OVERRIDES .DESKTOP ────────────────────────────────
inf "Creando overrides .desktop para apps pinneados en docklike..."
SETUP_LAUNCHERS="$KALITA_DIR/kalita-setup-launchers.sh"
if [ -f "$SETUP_LAUNCHERS" ]; then
    bash "$SETUP_LAUNCHERS"
    ok "Launchers configurados"
else
    warn "kalita-setup-launchers.sh no encontrado, saltando"
fi

# ── 25. ÍCONOS PAPIRUS-DARK NARANJOS (si está instalado) ────────────────────
if [ -d /usr/share/icons/Papirus-Dark ]; then
  inf "Aplicando íconos naranjos en Papirus-Dark..."
  _aplicar_iconos_naranja() {
    PAPIRUS="/usr/share/icons/Papirus-Dark"
    [ -d "${PAPIRUS}-backup-kalita" ] || cp -r "$PAPIRUS" "${PAPIRUS}-backup-kalita"

    for size in 16x16 22x22 24x24; do
      for icon in "$PAPIRUS/$size/panel"/network-wireless*.svg "$PAPIRUS/$size/panel"/bluetooth*.svg; do
        [ -f "$icon" ] && [ ! -L "$icon" ] && sed -i 's/color:#dfdfdf/color:#e6a23c/g' "$icon"
      done
    done

    for size in 16x16 22x22 24x24 32x32 48x48 64x64; do
      for icon in "$PAPIRUS/$size/places"/folder*.svg; do
        [ -f "$icon" ] && [ ! -L "$icon" ] && sed -i \
          -e 's/#5294e2/#e6a23c/g' -e 's/#4877b1/#c47a1e/g' \
          -e 's/#3a87e5/#d4891e/g' -e 's/#1d344f/#7a4a0f/g' "$icon"
      done
    done

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
  if [ "$(id -u)" = "0" ]; then
    _aplicar_iconos_naranja
  elif sudo -n true 2>/dev/null; then
    sudo bash -c "$(declare -f _aplicar_iconos_naranja); _aplicar_iconos_naranja"
  else
    warn "Sin sudo — ejecuta manualmente: sudo bash $0 para íconos naranjos"
  fi
fi

# ── 26. REINICIAR PANEL ──────────────────────────────────────────────────────
inf "Reiniciando panel XFCE..."
pkill xfce4-panel 2>/dev/null || true
sleep 1
xfce4-panel &
sleep 2
xfwm4 --replace & 2>/dev/null || true

# ── 27. MOUSE LOGI M196 — DIÁLOGO BT RECONEXIÓN ────────────────────────────
inf "Instalando diálogo de reconexión Logi M196 BT..."
mkdir -p "$SCRIPTS_DIR"

cat > "$SCRIPTS_DIR/mouse-logi-gui-connect.sh" << 'MOUSE_GUI_EOF'
#!/usr/bin/env bash
# Versión GUI-safe del reconector: sin sudo, sin bloqueo interactivo.
set -euo pipefail

MOUSE_NAME="Logi M196"
TIMEOUT=30

echo "[+] Buscando $MOUSE_NAME por BLE (${TIMEOUT}s)..."

OLD_ADDR=$(bluetoothctl devices 2>/dev/null | grep "$MOUSE_NAME" | awk '{print $2}' || true)
if [[ -n "$OLD_ADDR" ]]; then
    echo "[+] Eliminando emparejamiento anterior ($OLD_ADDR)..."
    bluetoothctl remove "$OLD_ADDR" 2>/dev/null || true
fi

NEW_ADDR=$(bluetoothctl --timeout "$TIMEOUT" scan le 2>&1 \
    | grep "NEW.*$MOUSE_NAME" \
    | awk '{print $3}' \
    | head -1 || true)

if [[ -z "$NEW_ADDR" ]]; then
    echo "[ERROR] No se encontró '$MOUSE_NAME' en ${TIMEOUT}s."
    echo "[!]    Asegúrate de que la luz del mouse parpadee rápido."
    exit 1
fi

echo "[+] Mouse encontrado: $NEW_ADDR"
echo "[+] Emparejando..."
bluetoothctl pair "$NEW_ADDR" 2>/dev/null || true
sleep 2

echo "[+] Confiando en el dispositivo..."
bluetoothctl trust "$NEW_ADDR"

echo "[+] Conectando..."
bluetoothctl connect "$NEW_ADDR"
sleep 1

CONNECTED=$(bluetoothctl info "$NEW_ADDR" 2>/dev/null | grep "Connected:" | awk '{print $2}' || echo "no")
if [[ "$CONNECTED" == "yes" ]]; then
    echo ""
    echo "[OK] $MOUSE_NAME conectado como $NEW_ADDR"
else
    echo "[!] Conexión reportada como no confirmada, pero puede funcionar igual."
fi

SERVICE=/etc/systemd/system/bt-connect-mouse.service
if [[ -f "$SERVICE" ]] && sudo -n true 2>/dev/null; then
    sudo sed -i "s/[0-9A-Fa-f:]\{17\}/$NEW_ADDR/g" "$SERVICE"
    sudo systemctl daemon-reload
    echo "[+] Servicio bt-connect-mouse actualizado con nueva dirección"
fi
MOUSE_GUI_EOF
chmod +x "$SCRIPTS_DIR/mouse-logi-gui-connect.sh"

cat > "$SCRIPTS_DIR/mouse-logi-check.sh" << 'MOUSE_CHECK_EOF'
#!/usr/bin/env bash
# Lanzado por XFCE autostart. Espera que la sesión esté lista,
# verifica si el mouse está conectado y abre el diálogo si no lo está.
MOUSE_NAME="Logi M196"
DIALOG="$HOME/scripts/mouse-logi-dialog.py"

sleep 6

is_connected() {
    local addr
    addr=$(bluetoothctl devices 2>/dev/null | grep "$MOUSE_NAME" | awk '{print $2}')
    [[ -z "$addr" ]] && return 1
    bluetoothctl info "$addr" 2>/dev/null | grep -q "Connected: yes"
}

if ! is_connected; then
    exec python3 "$DIALOG"
fi
MOUSE_CHECK_EOF
chmod +x "$SCRIPTS_DIR/mouse-logi-check.sh"

cat > "$SCRIPTS_DIR/mouse-logi-dialog.py" << 'MOUSE_DIALOG_EOF'
#!/usr/bin/env python3
"""
Diálogo de reconexión del Logi M196 — kAlita BT Reconnect
Aparece al inicio de sesión si el mouse no está conectado.
"""
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib, GdkPixbuf
import subprocess
import threading
import re
import os

MOUSE_NAME  = "Logi M196"
SCRIPT      = os.path.expanduser("~/scripts/mouse-logi-gui-connect.sh")
ICON_PATH   = "/usr/share/icons/Papirus/64x64/devices/blueman-mouse.svg"
ICON_FALLBACK = "blueman-mouse"

ANSI_RE = re.compile(r'\x1b\[[0-9;]*m')

CSS = b"""
window {
    background-color: #2b2b2b;
    color: #dddddd;
}
#header {
    background-color: #1e1e1e;
    padding: 12px 13px;
    border-bottom: 2px solid #181818;
}
#lbl-title {
    color: #e6a23c;
    font-weight: bold;
    font-size: 10px;
}
#lbl-sub {
    color: #666666;
    font-size: 7px;
    letter-spacing: 1px;
}
#status-box {
    background-color: #222222;
    border-radius: 4px;
    padding: 7px 9px;
    margin: 9px 10px 4px 10px;
    border: 1px solid #333333;
}
#lbl-status {
    font-size: 8px;
    color: #cccccc;
}
#lbl-addr {
    font-size: 7px;
    color: #555555;
    font-family: monospace;
}
.dot-ok {
    background-color: #4e9a5e;
    border-radius: 50%;
    min-width: 7px;
    min-height: 7px;
    min-width: 7px;
}
.dot-error {
    background-color: #9a4040;
    border-radius: 50%;
    min-width: 7px;
    min-height: 7px;
}
.dot-working {
    background-color: #c07820;
    border-radius: 50%;
    min-width: 7px;
    min-height: 7px;
}
#lbl-hint {
    color: #777777;
    font-size: 7px;
    padding: 3px 10px 1px 10px;
}
#lbl-log-header {
    color: #444444;
    font-size: 7px;
    letter-spacing: 1px;
    margin: 4px 10px 1px 10px;
}
textview {
    background-color: #1a1a1a;
    color: #888888;
    font-family: monospace;
    font-size: 7px;
}
textview text {
    background-color: #1a1a1a;
    color: #888888;
}
#scroll-log {
    border: 1px solid #2e2e2e;
    border-radius: 3px;
    margin: 0 10px 7px 10px;
}
#btn-reconnect {
    background-color: #b87020;
    color: #ffffff;
    font-weight: bold;
    font-size: 8px;
    border-radius: 3px;
    padding: 5px 13px;
    border: none;
    box-shadow: none;
    -gtk-icon-shadow: none;
}
#btn-reconnect:hover {
    background-color: #e6a23c;
    color: #1a1a1a;
}
#btn-reconnect:disabled {
    background-color: #3a3a3a;
    color: #555555;
}
#btn-close {
    background-color: #303030;
    color: #aaaaaa;
    border-radius: 3px;
    padding: 5px 9px;
    border: 1px solid #3d3d3d;
    box-shadow: none;
}
#btn-close:hover {
    background-color: #3a3a3a;
    color: #dddddd;
}
#btn-box {
    padding: 4px 10px 10px 10px;
}
"""


class MouseDialog(Gtk.Window):
    def __init__(self):
        super().__init__(title="Logitech M196 — Bluetooth")
        self.set_default_size(312, 319)
        self.set_resizable(False)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_icon_name(ICON_FALLBACK)
        self._pulse_id = None
        self._dot_state = True

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self._build_ui()
        self.show_all()
        GLib.idle_add(self._check_status)

    def _build_ui(self):
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(root)

        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=9)
        header.set_name("header")
        try:
            pb = GdkPixbuf.Pixbuf.new_from_file_at_size(ICON_PATH, 36, 36)
            icon = Gtk.Image.new_from_pixbuf(pb)
        except Exception:
            icon = Gtk.Image.new_from_icon_name(ICON_FALLBACK, Gtk.IconSize.DIALOG)
        header.pack_start(icon, False, False, 0)

        vt = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        vt.set_valign(Gtk.Align.CENTER)
        t = Gtk.Label(label="Mouse Logitech M196")
        t.set_name("lbl-title")
        t.set_halign(Gtk.Align.START)
        s = Gtk.Label(label="BLUETOOTH LOW ENERGY  ·  KALITA RECONNECT")
        s.set_name("lbl-sub")
        s.set_halign(Gtk.Align.START)
        vt.pack_start(t, False, False, 0)
        vt.pack_start(s, False, False, 0)
        header.pack_start(vt, True, True, 0)
        root.pack_start(header, False, False, 0)

        sb = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=7)
        sb.set_name("status-box")
        self.dot = Gtk.Box()
        self.dot.set_valign(Gtk.Align.CENTER)
        self._dot_set("error")
        self.lbl_status = Gtk.Label(label="Verificando conexión…")
        self.lbl_status.set_name("lbl-status")
        self.lbl_status.set_halign(Gtk.Align.START)
        self.lbl_status.set_hexpand(True)
        self.lbl_addr = Gtk.Label(label="")
        self.lbl_addr.set_name("lbl-addr")
        sb.pack_start(self.dot, False, False, 0)
        sb.pack_start(self.lbl_status, True, True, 0)
        sb.pack_start(self.lbl_addr, False, False, 0)
        root.pack_start(sb, False, False, 0)

        self.lbl_hint = Gtk.Label()
        self.lbl_hint.set_name("lbl-hint")
        self.lbl_hint.set_halign(Gtk.Align.START)
        self.lbl_hint.set_line_wrap(True)
        self.lbl_hint.set_markup(
            'Presiona el botón inferior del mouse hasta que la '
            '<b><span foreground="#e6a23c">luz parpadee rápido</span></b> '
            '(modo pairing activo), luego presiona <b>Reconectar</b>.'
        )
        root.pack_start(self.lbl_hint, False, False, 0)

        lh = Gtk.Label(label="REGISTRO")
        lh.set_name("lbl-log-header")
        lh.set_halign(Gtk.Align.START)
        root.pack_start(lh, False, False, 0)

        scroll = Gtk.ScrolledWindow()
        scroll.set_name("scroll-log")
        scroll.set_hexpand(True)
        scroll.set_vexpand(True)
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.tv = Gtk.TextView()
        self.tv.set_editable(False)
        self.tv.set_cursor_visible(False)
        self.tv.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.tv.set_left_margin(8)
        self.tv.set_right_margin(8)
        self.tv.set_top_margin(6)
        self.tv.set_bottom_margin(6)
        self.buf = self.tv.get_buffer()
        scroll.add(self.tv)
        root.pack_start(scroll, True, True, 0)

        bb = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        bb.set_name("btn-box")
        bb.set_halign(Gtk.Align.END)
        self.btn_close = Gtk.Button(label="Cerrar")
        self.btn_close.set_name("btn-close")
        self.btn_close.connect("clicked", lambda _: Gtk.main_quit())
        self.btn_rec = Gtk.Button(label="  Reconectar Mouse  ")
        self.btn_rec.set_name("btn-reconnect")
        self.btn_rec.connect("clicked", self._on_reconnect)
        bb.pack_end(self.btn_rec, False, False, 0)
        bb.pack_end(self.btn_close, False, False, 0)
        root.pack_start(bb, False, False, 0)

    def _dot_set(self, state):
        ctx = self.dot.get_style_context()
        for c in ("dot-ok", "dot-error", "dot-working"):
            ctx.remove_class(c)
        ctx.add_class(f"dot-{state}")

    def _log(self, line):
        line = ANSI_RE.sub("", line).rstrip()
        end = self.buf.get_end_iter()
        self.buf.insert(end, line + "\n")
        adj = self.tv.get_parent().get_vadjustment()
        GLib.idle_add(lambda: adj.set_value(adj.get_upper()))

    def _set_status(self, text, state, addr=""):
        self.lbl_status.set_text(text)
        self._dot_set(state)
        self.lbl_addr.set_text(addr)

    def _pulse_start(self):
        self._pulse_id = GLib.timeout_add(500, self._pulse_tick)

    def _pulse_stop(self):
        if self._pulse_id:
            GLib.source_remove(self._pulse_id)
            self._pulse_id = None
        self._dot_set("working")

    def _pulse_tick(self):
        self._dot_state = not self._dot_state
        self._dot_set("working" if self._dot_state else "error")
        return True

    def _is_connected(self):
        try:
            devs = subprocess.run(
                ["bluetoothctl", "devices"],
                capture_output=True, text=True, timeout=5
            ).stdout
            for line in devs.strip().splitlines():
                if MOUSE_NAME in line:
                    addr = line.split()[1]
                    info = subprocess.run(
                        ["bluetoothctl", "info", addr],
                        capture_output=True, text=True, timeout=5
                    ).stdout
                    if "Connected: yes" in info:
                        return True, addr
        except Exception:
            pass
        return False, None

    def _check_status(self):
        def worker():
            ok, addr = self._is_connected()
            GLib.idle_add(self._apply_status, ok, addr)
        threading.Thread(target=worker, daemon=True).start()

    def _apply_status(self, ok, addr):
        if ok:
            self._set_status("Conectado y funcionando", "ok", addr or "")
            self._log(f"[OK] Mouse detectado: {addr}")
            self.btn_rec.set_sensitive(False)
            self.lbl_hint.set_markup(
                '<span foreground="#4e9a5e">El mouse está conectado correctamente.</span>'
            )
        else:
            self._set_status("Sin conexión — mouse no detectado", "error")
            self._log("[!] El mouse no se detectó al iniciar sesión")
            self._log("[!] Activa el modo pairing y presiona Reconectar")

    def _on_reconnect(self, _widget):
        self.btn_rec.set_sensitive(False)
        self._set_status("Buscando mouse en modo pairing…", "working")
        self._pulse_start()
        self._log("")
        self._log("[+] Iniciando reconexión Bluetooth LE…")

        def worker():
            try:
                proc = subprocess.Popen(
                    ["bash", SCRIPT],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True
                )
                for line in proc.stdout:
                    GLib.idle_add(self._log, line)
                proc.wait()
                ok = proc.returncode == 0
            except Exception as e:
                GLib.idle_add(self._log, f"[ERROR] {e}")
                ok = False
            connected, addr = self._is_connected()
            GLib.idle_add(self._reconnect_done, connected, addr)

        threading.Thread(target=worker, daemon=True).start()

    def _reconnect_done(self, ok, addr):
        self._pulse_stop()
        if ok:
            self._set_status("Reconectado exitosamente", "ok", addr or "")
            self._log(f"\n[OK] Mouse listo: {addr}")
            self.btn_close.set_label("Cerrar")
            self.lbl_hint.set_markup(
                '<span foreground="#4e9a5e">Conexión establecida. Esta ventana se cerrará en 4 segundos.</span>'
            )
            GLib.timeout_add_seconds(4, Gtk.main_quit)
        else:
            self._set_status("No se pudo conectar — intenta de nuevo", "error")
            self._log("\n[!] Asegúrate de que la luz del mouse parpadee rápido")
            self.btn_rec.set_sensitive(True)


def main():
    win = MouseDialog()
    win.connect("destroy", Gtk.main_quit)
    Gtk.main()


if __name__ == "__main__":
    main()
MOUSE_DIALOG_EOF
chmod +x "$SCRIPTS_DIR/mouse-logi-dialog.py"

# Autostart — verificar BT al iniciar sesión
cat > "$HOME/.config/autostart/mouse-logi-check.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Mouse Logi M196 — BT Check
Comment=Verifica conexión Bluetooth del mouse al iniciar sesión
Exec=bash /home/rcaceres/scripts/mouse-logi-check.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Terminal=false
EOF
ok "Mouse Logi BT reconnect instalado"

# ── 28. POWER-SAVER POR DEFECTO ─────────────────────────────────────────────
inf "Configurando perfil de energía power-saver por defecto..."
if command -v powerprofilesctl &>/dev/null; then
  sudo tee /etc/systemd/system/power-saver-default.service > /dev/null << 'EOF'
[Unit]
Description=Set power profile to power-saver on boot
After=power-profiles-daemon.service
Requires=power-profiles-daemon.service

[Service]
Type=oneshot
ExecStart=/usr/bin/powerprofilesctl set power-saver
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable --now power-saver-default.service 2>/dev/null || true
  ok "power-saver activado por defecto (systemd)"
else
  warn "powerprofilesctl no disponible, saltando"
fi

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   kAlita instalado correctamente!    ║"
echo "║  SSH reverso: ssh -p 2222 en petria ║"
echo "║  Recomendado: cerrar sesión y entrar ║"
echo "╚══════════════════════════════════════╝"
echo ""
