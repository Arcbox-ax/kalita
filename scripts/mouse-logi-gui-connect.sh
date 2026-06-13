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

# Actualizar servicio systemd si existe y sudo está disponible sin contraseña
SERVICE=/etc/systemd/system/bt-connect-mouse.service
if [[ -f "$SERVICE" ]] && sudo -n true 2>/dev/null; then
    sudo sed -i "s/[0-9A-Fa-f:]\{17\}/$NEW_ADDR/g" "$SERVICE"
    sudo systemctl daemon-reload
    echo "[+] Servicio bt-connect-mouse actualizado con nueva dirección"
fi
