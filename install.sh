#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════
# Config und Skripte an ihren Platz legen
#
#   ./install.sh          verlinkt alles nach ~/.config/aerospace/
#   ./install.sh status   zeigt, was gerade verlinkt ist
#
# Alles landet in ~/.config/aerospace/ — dort sucht AeroSpace seine
# Config von sich aus, und die Hotkeys in aerospace.toml zeigen ohnehin
# auf ~/.config/aerospace/env/.
#
# Bewusst NICHT ~/.aerospace.toml: AeroSpace sucht in beiden Pfaden und
# meldet einen Fehler, wenn die Config an zwei Orten liegt.
#
# Verlinkt statt kopiert — dadurch ist der Projektordner die einzige
# Quelle der Wahrheit, und mit auto-reload-config greift jede Änderung
# sofort. Wenn du den Projektordner verschiebst: dieses Skript erneut
# laufen lassen.
# ══════════════════════════════════════════════════════════════════════
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DST="$HOME/.config/aerospace"

if [ "${1:-}" = "status" ]; then
  echo "Ziel: $DST"
  for p in aerospace.toml env macos; do
    if [ -L "$DST/$p" ]; then
      printf "  %-16s → %s\n" "$p" "$(readlink "$DST/$p")"
    elif [ -e "$DST/$p" ]; then
      printf "  %-16s (echte Datei, kein Symlink)\n" "$p"
    else
      printf "  %-16s fehlt\n" "$p"
    fi
  done
  echo
  ls -1 "$DST"/*.backup-* 2>/dev/null | sed 's|^|  Backup: |' || echo "  (keine Backups)"
  exit 0
fi

mkdir -p "$DST"

# Bestehende echte Config sichern, bevor sie ersetzt wird
if [ -f "$DST/aerospace.toml" ] && [ ! -L "$DST/aerospace.toml" ]; then
  BAK="$DST/aerospace.toml.backup-$(date +%Y%m%d-%H%M%S)"
  mv "$DST/aerospace.toml" "$BAK"
  echo "Alte Config gesichert: $BAK"
fi

ln -sfn "$SRC/aerospace.toml" "$DST/aerospace.toml"
ln -sfn "$SRC/env"            "$DST/env"
ln -sfn "$SRC/macos"          "$DST/macos"

# Ghostty-Config: Tabs abgeschaltet, weil native macOS-Tabs und AeroSpace
# sich nicht verträgen (siehe ghostty/config)
mkdir -p "$HOME/.config/ghostty"
if [ -f "$HOME/.config/ghostty/config" ] && [ ! -L "$HOME/.config/ghostty/config" ]; then
  mv "$HOME/.config/ghostty/config" "$HOME/.config/ghostty/config.backup-$(date +%Y%m%d-%H%M%S)"
  echo "Alte Ghostty-Config gesichert"
fi
ln -sfn "$SRC/ghostty/config" "$HOME/.config/ghostty/config"
chmod +x "$SRC/env/"*.sh "$SRC/macos/"*.sh "$SRC/install.sh"

# Ambiguität vermeiden: AeroSpace würde meckern, wenn beide Pfade existieren
if [ -e "$HOME/.aerospace.toml" ]; then
  mv "$HOME/.aerospace.toml" "$HOME/.aerospace.toml.disabled-$(date +%Y%m%d)"
  echo "~/.aerospace.toml beiseitegelegt (sonst meldet AeroSpace Ambiguität)"
fi

echo
echo "Verlinkt:"
ls -la "$DST" | grep -E "aerospace.toml|env|macos"
echo
echo "Prüfen:"
echo "  aerospace reload-config --dry-run"
echo "  aerospace list-monitors"
