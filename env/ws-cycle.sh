#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════
# ws-cycle — Workspace weiterblaettern, ohne in einer Sackgasse zu landen
#
#   ws-cycle.sh next | prev
#
# `aerospace workspace next` blaettert NUR die Workspaces des Monitors,
# auf dem der Fokus gerade steht. Seit dem 12.10.2026 haben zwei der drei
# Monitore genau einen Workspace (G61SH → 1, intern → 4). Dort tat
# ctrl+←/→ deshalb gar nichts — gemessen: drei Tastendruecke, Fokus blieb
# auf Workspace 4.
#
# Dieses Skript behaelt das bisherige Verhalten bei und faengt nur den
# Fall ab, dass es nicht weitergeht: dann rutscht der Fokus auf den
# naechsten Monitor. Auf dem grossen Samsung aendert sich nichts.
#
# ⚠️ ENTSCHEIDUNG VORHER, NICHT NACHHER. Die erste Fassung schaltete
# erst um und verglich danach den Fokus — und weil AeroSpace ihn noch
# nicht gesetzt hatte, sah der Vergleich "unveraendert" und schaltete
# zusaetzlich den Monitor weiter. Ergebnis: zwei Spruenge statt einem,
# gemessen am 12.10.2026 (Workspace 2 → 4 statt 2 → 3). Ein Rennen gegen
# die Zeit. Jetzt wird vorher gezaehlt, wie viele Workspaces der
# fokussierte Monitor hat — das ist deterministisch.
#
# BEWUSST KEIN globales 1→2→…→7: das haette das Blaettern auf dem grossen
# Samsung veraendert (von 7 nach 1 statt zurueck nach 2).
# ══════════════════════════════════════════════════════════════════════
set -euo pipefail

AERO="$(command -v aerospace || echo /opt/homebrew/bin/aerospace)"

dir="${1:-next}"
case "$dir" in
  next|prev) ;;
  *) echo "Aufruf: $(basename "$0") next|prev" >&2; exit 2 ;;
esac

# Workspaces dieses Monitors, in ihrer Reihenfolge, plus der aktuelle.
mapfile_compat() { while IFS= read -r l; do printf '%s\n' "$l"; done; }
list="$("$AERO" list-workspaces --monitor focused 2>/dev/null | mapfile_compat)"
cur="$("$AERO" list-workspaces --focused 2>/dev/null)"

first="$(printf '%s\n' "$list" | head -1)"
last="$(printf '%s\n'  "$list" | tail -1)"

# Am Rand des Monitors? Dann eine Etage hoeher. Sonst normal blaettern.
#
# ⚠️ KEIN --wrap-around beim Workspace-Schritt. Mit wrap-around kreist
# der Fokus innerhalb des Monitors (2→3→5→6→7→2) und verlaesst ihn nie —
# dieselbe Sackgasse, nur verschoben. Am 12.10.2026 genau so gemessen.
#
# Die Randpruefung passiert VORHER, nicht durch Vergleich hinterher: die
# erste Fassung schaltete erst um und verglich danach den Fokus, den
# AeroSpace noch nicht gesetzt hatte — Ergebnis waren zwei Spruenge
# statt einem.
if { [ "$dir" = next ] && [ "$cur" = "$last" ]; } \
|| { [ "$dir" = prev ] && [ "$cur" = "$first" ]; }; then
  "$AERO" focus-monitor --wrap-around "$dir"
  # Auf dem neuen Monitor an den passenden RAND springen, nicht auf den
  # zuletzt fokussierten Workspace. Sonst ist der Rundlauf unregelmaessig:
  # gemessen am 12.10.2026 sprang er 1 → 2 → … → 7 → 4 → 1 → 7, weil
  # focus-monitor den grossen Samsung bei seinem letzten Workspace (7)
  # wieder aufnahm und von dort sofort weiter musste. So laeuft ctrl+→
  # stattdessen sauber von links nach rechts durch alle Workspaces.
  nxt="$("$AERO" list-workspaces --monitor focused 2>/dev/null \
        | { [ "$dir" = next ] && head -1 || tail -1; })"
  now="$("$AERO" list-workspaces --focused 2>/dev/null)"
  # Nur springen, wenn es etwas zu springen gibt — sonst meldet AeroSpace
  # "Workspace 'N' is already focused" und muellt das Log voll.
  if [ -n "$nxt" ] && [ "$nxt" != "$now" ]; then
    exec "$AERO" workspace "$nxt"
  fi
  exit 0
else
  # ⚠️ --no-stdin ist Pflicht. Seit AeroSpace 0.20 verweigert die
  # (next|prev)-Form den Dienst, wenn stdin kein Terminal ist — also
  # genau dann, wenn sie aus einem Skript laeuft. Ohne das Flag kommt
  # "Implicit stdin is detected" und es passiert nichts. Aus der
  # aerospace.toml heraus faellt das nicht auf, weil AeroSpace den
  # Befehl dort selbst ausfuehrt; erst der Umweg ueber das Skript
  # braucht es.
  exec "$AERO" workspace --no-stdin "$dir"
fi
