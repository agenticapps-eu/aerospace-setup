#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════
# WS-OPEN · einen einzelnen Workspace aufbauen        ws-open.sh <n>
#
# KEIN @label — dieses Skript ist die Maschine, nicht der Knopf. Die
# Knöpfe sind die dünnen ws-<n>-*.sh daneben; nur die tauchen in
# AeroPilot auf.
#
# Baut GENAU einen Workspace: öffnet die Apps, die in layout.conf für
# ihn mit führendem `+` markiert sind, schiebt sie hin, richtet das
# Layout und springt hin. Der kleine Bruder von build-all.sh.
#
# WARUM AUS layout.conf UND NICHT AUS EINER EIGENEN LISTE:
# Es gibt schon drei Stellen, an denen eine App-Zuordnung stehen kann
# (aerospace.toml, layout.conf, offene Fenster). Eine vierte wäre die
# sichere Art, sie auseinanderlaufen zu lassen — genau das ist am
# 26.08.2026 beim Obsidian-Tausch passiert.
#
# Ghostty kann nicht über layout.conf geöffnet werden: alle Fenster
# teilen eine Bundle-ID, unterschieden wird am Titel. Für die drei
# Ghostty-Workspaces ruft dieses Skript deshalb die vorhandenen
# ghostty-*.sh auf, statt deren Logik zu doppeln.
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

ws="${1:-}"
case "$ws" in
  [1-7]) ;;
  *) echo "Aufruf: ws-open.sh <1-7>" >&2; exit 1 ;;
esac

read_layout || exit 1

# ── Ghostty-Fenster über die bestehenden Skripte ──────────────────────
rmdir "$LOCKDIR" 2>/dev/null; trap - EXIT
mode="$(python3 "$HERE/layout.py" mode)"
if [ "$mode" = laptop ]; then
  case "$ws" in
    1) "$HERE/gt.sh" herdr ;;
    2) "$HERE/gt.sh" hermes ;;
    3) "$HERE/gt.sh" homelab ;;
  esac
else
case "$ws" in
  1) "$HERE/ghostty-herdr.sh"  >/dev/null 2>&1 ;;
  5) "$HERE/ghostty-remote.sh" >/dev/null 2>&1 ;;
  6) "$HERE/ghostty-tools.sh"  >/dev/null 2>&1 ;;
esac
fi

# ── Die übrigen Apps dieses Workspace ─────────────────────────────────
# Nur die mit `+`: ohne Markierung heisst "ordne sie ein, wenn sie
# laufen" — nicht "starte sie".
anzahl=0
i=0
while [ "$i" -lt "${#r_bundle[@]}" ]; do
  if [ "${r_ws[$i]}" = "$ws" ] && [ "${r_auto[$i]}" = "ja" ]; then
    case "${r_bundle[$i]}" in
      com.mitchellh.ghostty) ;;          # oben schon erledigt
      *) place_one "${r_bundle[$i]}" "$ws"; anzahl=$((anzahl+1)) ;;
    esac
  fi
  i=$((i+1))
done

# ── Richten und hinspringen ───────────────────────────────────────────
"$HERE/relayout.sh"
"$AERO" workspace "$ws" 2>/dev/null

echo "Workspace $ws aufgebaut ($anzahl Apps)"
