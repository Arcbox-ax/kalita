#!/usr/bin/env bash
set -e

NET_IF="wlan0"
CONKY_DIR="$HOME/.config/conky"
CONKY_CONF="$CONKY_DIR/conky.conf"
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/conky-kalita.desktop"

echo "[+] Instalando Conky y sensores..."
sudo apt update
sudo apt install -y conky-all lm-sensors dbus-x11

echo "[+] Creando carpetas..."
mkdir -p "$CONKY_DIR"
mkdir -p "$AUTOSTART_DIR"

echo "[+] Creando configuración de Conky..."
cat > "$CONKY_CONF" <<'EOF'
conky.config = {
    alignment = 'top_right',
    background = true,
    update_interval = 1,
    double_buffer = true,
    no_buffers = true,

    use_xft = true,
    font = 'DejaVu Sans Mono:size=10',
    override_utf8_locale = true,

    own_window = true,
    own_window_class = 'Conky',
    own_window_type = 'desktop',
    own_window_transparent = true,
    own_window_argb_visual = true,
    own_window_argb_value = 70,
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',

    minimum_width = 320,
    maximum_width = 320,
    gap_x = 25,
    gap_y = 45,

    draw_shades = false,
    draw_outline = false,
    draw_borders = false,

    default_color = 'white',
    color1 = 'cyan',
    color2 = 'lightgrey',
    color3 = 'orange',
};

conky.text = [[
${color1}${font DejaVu Sans Mono:bold:size=13}kAlita Monitor${font}${color}
${hr}

${color1}Sistema:${color}
Host: $nodename
Kernel: $kernel
Uptime: $uptime

${color1}CPU:${color} ${cpu cpu0}%
${cpubar cpu0 8}
${cpugraph cpu0 30,300}

${color1}RAM:${color} $mem / $memmax - $memperc%
${membar 8}

${color1}Swap:${color} $swap / $swapmax - $swapperc%
${swapbar 8}

${color1}Disco /:${color}
${fs_used /} / ${fs_size /} - ${fs_used_perc /}%
${fs_bar 8 /}

${color1}Red wlan0:${color}
IP: ${addr __NET_IF__}
Down: ${downspeedf __NET_IF__} KiB/s
Up:   ${upspeedf __NET_IF__} KiB/s
${downspeedgraph __NET_IF__ 25,145} ${upspeedgraph __NET_IF__ 25,145}

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

sed -i "s/__NET_IF__/$NET_IF/g" "$CONKY_CONF"

echo "[+] Creando inicio automático..."
cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Conky kAlita Monitor
Comment=Monitor de CPU, RAM, red y disco en el escritorio
Exec=sh -c "sleep 5 && conky -c $CONKY_CONF"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Terminal=false
EOF

echo "[+] Activando compositor de XFWM4 (necesario para transparencia)..."
xfconf-query -c xfwm4 -p /general/use_compositing -s true 2>/dev/null || true

echo "[+] Cerrando Conky anterior si existe..."
pkill conky 2>/dev/null || true

echo "[+] Iniciando Conky..."
conky -c "$CONKY_CONF" &

echo ""
echo "[OK] Conky instalado y configurado."
echo "[OK] Interfaz de red usada: $NET_IF"
echo "[OK] Configuración: $CONKY_CONF"
echo "[OK] Inicio automático: $AUTOSTART_FILE"
echo ""
echo "Para apagarlo:"
echo "  pkill conky"
echo ""
echo "Para volver a iniciarlo:"
echo "  conky -c $CONKY_CONF &"
