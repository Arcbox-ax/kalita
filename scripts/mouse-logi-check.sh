#!/usr/bin/env bash
# Lanzado por XFCE autostart. Espera que la sesión esté lista,
# verifica si el mouse está conectado y abre el diálogo si no lo está.
MOUSE_NAME="Logi M196"
DIALOG="$HOME/scripts/mouse-logi-dialog.py"

# Esperar que el entorno gráfico esté listo
sleep 6

# Verificar si el mouse ya está conectado
is_connected() {
    local addr
    addr=$(bluetoothctl devices 2>/dev/null | grep "$MOUSE_NAME" | awk '{print $2}')
    [[ -z "$addr" ]] && return 1
    bluetoothctl info "$addr" 2>/dev/null | grep -q "Connected: yes"
}

if ! is_connected; then
    exec python3 "$DIALOG"
fi
