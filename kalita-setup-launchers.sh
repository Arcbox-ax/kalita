#!/usr/bin/env bash
# kalita-setup-launchers.sh
# Crea .desktop overrides en ~/.local/share/applications/ para todos los apps
# pinneados en docklike, envolviendo su Exec con kalita-launch.
# Idempotente: se puede correr múltiples veces.

set -euo pipefail

APPS_DIR="$HOME/.local/share/applications"
LAUNCH_BIN="$HOME/scripts/kalita-launch"
SEARCH_DIRS=(
    /usr/share/applications
    /var/lib/flatpak/exports/share/applications
    ~/.local/share/flatpak/exports/share/applications
    ~/.local/share/applications
)

mkdir -p "$APPS_DIR"

# Leer pinned del docklike
DOCKLIKE_RC=$(find ~/.config/xfce4/panel/ -name "docklike-*.rc" 2>/dev/null | head -1 || true)
if [ -z "$DOCKLIKE_RC" ]; then
    echo "[!] No se encontró config de docklike"
    exit 1
fi

PINNED=$(grep "^pinned=" "$DOCKLIKE_RC" | cut -d= -f2 | tr ';' '\n' | grep -v '^$')
echo "[+] Apps pinneados encontrados: $(echo "$PINNED" | wc -l)"

_find_desktop() {
    local app_id="$1"
    for dir in "${SEARCH_DIRS[@]}"; do
        local f="${dir}/${app_id}.desktop"
        [ -f "$f" ] && echo "$f" && return 0
    done
    # Buscar con find como fallback
    find "${SEARCH_DIRS[@]}" -name "${app_id}.desktop" 2>/dev/null | head -1 || true
}

_wrap_app() {
    local app_id="$1"
    local desktop_src="$2"
    local out="$APPS_DIR/${app_id}.desktop"

    # Obtener WM_CLASS del .desktop original (o usar app_id como fallback)
    local wm_class
    wm_class=$(grep "^StartupWMClass=" "$desktop_src" 2>/dev/null | cut -d= -f2 | head -1 || true)
    [ -z "$wm_class" ] && wm_class="${app_id##*.}"  # último segmento del app_id
    wm_class="${wm_class,,}"  # minúsculas

    # Copiar .desktop original (no copiar si src ya es el destino)
    [ "$desktop_src" != "$out" ] && cp "$desktop_src" "$out"

    # Reemplazar CADA línea Exec= (puede haber varias para acciones)
    # Solo la principal (sin acción) se envuelve con kalita-launch
    local exec_line
    exec_line=$(grep "^Exec=" "$desktop_src" | head -1 | sed 's/^Exec=//')

    # Construir nuevo Exec envuelto
    local new_exec="Exec=${LAUNCH_BIN} ${app_id} ${wm_class} ${exec_line}"

    # Reemplazar primera línea Exec= (la principal)
    sed -i "0,/^Exec=/{s|^Exec=.*|${new_exec}|}" "$out"

    # Marcar como override de kalita
    grep -q "^X-KalitaLaunch=" "$out" || echo "X-KalitaLaunch=true" >> "$out"

    echo "[+] $app_id → wm_class=$wm_class"
}

WRAPPED=0
SKIPPED=0

while IFS= read -r app_id; do
    [ -z "$app_id" ] && continue

    desktop_src=$(_find_desktop "$app_id")

    if [ -z "$desktop_src" ]; then
        echo "[!] Sin .desktop para $app_id — saltando"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Si el .desktop ya está en APPS_DIR (override manual), no tocarlo nunca
    # a menos que ya tenga X-KalitaLaunch=true (fue puesto por este script)
    if [[ "$desktop_src" == "$APPS_DIR/"* ]]; then
        if grep -q "X-KalitaLaunch=true" "$desktop_src" 2>/dev/null; then
            echo "[-] $app_id ya envuelto en origen"
        else
            echo "[-] $app_id es override manual, no se toca"
        fi
        continue
    fi

    # No envolver si ya está envuelto y el src no cambió
    out="$APPS_DIR/${app_id}.desktop"
    if [ -f "$out" ] && grep -q "X-KalitaLaunch=true" "$out" 2>/dev/null; then
        if [ "$desktop_src" -ot "$out" ]; then
            echo "[-] $app_id ya envuelto (sin cambios)"
            continue
        fi
    fi

    _wrap_app "$app_id" "$desktop_src"
    WRAPPED=$((WRAPPED + 1))
done <<< "$PINNED"

# Actualizar caché de apps
update-desktop-database "$APPS_DIR" 2>/dev/null || true

echo ""
echo "[OK] $WRAPPED apps envueltos, $SKIPPED saltados"
echo "     Reinicia el panel para que docklike use los nuevos launchers:"
echo "     pkill -x xfce4-panel && xfce4-panel &"
