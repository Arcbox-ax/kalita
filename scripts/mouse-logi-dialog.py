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

    # ── UI ──────────────────────────────────────────────────────────────────

    def _build_ui(self):
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(root)

        # Header
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

        # Status row
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

        # Hint
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

        # Log area
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

        # Buttons
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

    # ── helpers ─────────────────────────────────────────────────────────────

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

    # ── pulse animation while connecting ────────────────────────────────────

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

    # ── logic ────────────────────────────────────────────────────────────────

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
