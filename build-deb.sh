#!/usr/bin/env bash
# build-deb.sh — Construye el paquete .deb de kAlita
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="1.0.0"
PKG_NAME="kalita"
ARCH="all"
PKG_DIR="$REPO_DIR/pkg/${PKG_NAME}_${VERSION}_${ARCH}"
SHARE_DIR="$PKG_DIR/usr/share/kalita"
BIN_DIR="$PKG_DIR/usr/local/bin"

echo "[+] Limpiando build anterior..."
rm -rf "$REPO_DIR/pkg"
mkdir -p "$SHARE_DIR/assets" "$SHARE_DIR/scripts" "$BIN_DIR" "$PKG_DIR/DEBIAN"

echo "[+] Copiando scripts kalita..."
for f in "$REPO_DIR"/*.sh; do
    [[ "$(basename "$f")" == "build-deb.sh" ]] && continue
    cp "$f" "$SHARE_DIR/"
done

echo "[+] Copiando assets..."
cp -r "$REPO_DIR/assets/"* "$SHARE_DIR/assets/"

echo "[+] Copiando scripts de ~/scripts/ (mouse-logi)..."
for f in mouse-logi-dialog.py mouse-logi-gui-connect.sh mouse-logi-check.sh; do
    src="$HOME/scripts/$f"
    [ -f "$src" ] && cp "$src" "$SHARE_DIR/scripts/" || echo "[!] $f no encontrado, saltando"
done

chmod -R 755 "$SHARE_DIR"

echo "[+] Creando wrapper /usr/local/bin/kalita..."
cat > "$BIN_DIR/kalita" << 'EOF'
#!/usr/bin/env bash
exec bash /usr/share/kalita/kalita-instalar.sh "$@"
EOF
chmod 755 "$BIN_DIR/kalita"

echo "[+] Creando DEBIAN/control..."
INSTALLED_SIZE=$(du -sk "$PKG_DIR" | awk '{print $1}')
cat > "$PKG_DIR/DEBIAN/control" << CTRL
Package: $PKG_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: Robinson Cáceres <robinson@exipm.cl>
Installed-Size: $INSTALLED_SIZE
Depends: xfce4, xfconf, python3-gi, python3-gi-cairo, gir1.2-gtk-3.0, conky-all, picom, blueman, fonts-noto, papirus-icon-theme
Recommends: flatpak, plank, xdotool, wmctrl
Description: kAlita — Entorno XFCE personalizado para Kali Linux
 Scripts de tema, dock, panel, terminal y autostart para Kali Linux XFCE.
 Incluye diálogo Bluetooth para mouse Logitech M196, tema kAlita-orange-dark,
 Conky monitor, Picom compositor, y lanzadores .desktop optimizados.
 .
 Después de instalar, ejecuta: kalita
CTRL

echo "[+] Creando DEBIAN/postinst..."
cat > "$PKG_DIR/DEBIAN/postinst" << 'POSTINST'
#!/usr/bin/env bash
set -e
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   kAlita instalado en el sistema.        ║"
echo "║   Para aplicar la config a tu sesión:    ║"
echo "║      kalita                              ║"
echo "╚══════════════════════════════════════════╝"
echo ""
POSTINST
chmod 755 "$PKG_DIR/DEBIAN/postinst"

echo "[+] Construyendo .deb..."
dpkg-deb --build --root-owner-group "$PKG_DIR" "$REPO_DIR/dist/"
DEB_FILE=$(ls "$REPO_DIR/dist/"*.deb)
echo ""
echo "[OK] Paquete creado: $DEB_FILE"
echo "[OK] Instalar con: sudo apt install $DEB_FILE"
echo "[OK] Aplicar config: kalita"
