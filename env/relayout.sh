#!/usr/bin/env bash
# @group: Aufbauen
# @label: Layouts richten
# @key:   alt-ctrl-r
# ══════════════════════════════════════════════════════════════════════
# RELAYOUT — alle Fenster an ihren Platz               Hotkey: alt-ctrl-r
#
# Liest env/layout.conf und schiebt jedes offene Fenster dorthin, wo es
# laut Soll-Tabelle hingehört. Öffnet nichts, beendet nichts.
#
# WAS SICH GEÄNDERT HAT (20.08.2026): vorher standen die Zuordnungen hier
# im Skript und deckten nur die Workspaces 2 und 3 ab. Als die Workspaces
# umnummeriert wurden, lagen deshalb Fenster auf 5, 6 und 7 tagelang
# falsch, ohne dass alt-ctrl-r etwas daran geändert hätte. Jetzt gibt es
# genau eine Quelle, und sie deckt alles ab.
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
CONF="$HERE/layout.conf"

[ -f "$CONF" ] || { echo "Soll-Tabelle fehlt: $CONF"; exit 1; }

# ── Soll-Tabelle einlesen ─────────────────────────────────────────────
# Parallele Arrays statt assoziativem Array: macOS bringt bash 3.2 mit,
# `declare -A` gibt es dort nicht. Ausserdem ist die REIHENFOLGE hier
# bedeutungstragend — erste Übereinstimmung gewinnt.
r_bundle=(); r_ws=(); r_title=()
while IFS= read -r line; do
  line="${line%%#*}"
  [ -z "${line// /}" ] && continue
  read -r b w t <<< "$line"
  [ -z "$b" ] && continue
  r_bundle+=("$b"); r_ws+=("$w"); r_title+=("$t")
done < "$CONF"
echo "Soll-Tabelle: ${#r_bundle[@]} Regeln"

# ── Fenster durchgehen ────────────────────────────────────────────────
moved=0; checked=0
while IFS='|' read -r id bundle ws title; do
  [ -z "$id" ] && continue
  checked=$((checked+1))
  for i in "${!r_bundle[@]}"; do
    [ "${r_bundle[$i]}" = "$bundle" ] || continue
    # Regel mit Titelmuster gilt nur bei passendem Titel; ohne Muster
    # passt sie immer. So gewinnt die spezifischere Regel, weil sie in
    # der Datei vorne steht.
    if [ -n "${r_title[$i]}" ]; then
      [[ "$title" =~ ${r_title[$i]} ]] || continue
    fi
    target="${r_ws[$i]}"
    if [ "$target" != "-" ] && [ "$target" != "$ws" ]; then
      "$AERO" move-node-to-workspace --window-id "$id" "$target" >/dev/null 2>&1 \
        && { echo "  $ws → $target   $title"; moved=$((moved+1)); } \
        || echo "  FEHLER bei $id ($title)"
    fi
    break   # erste Übereinstimmung gewinnt
  done
done <<< "$("$AERO" list-windows --monitor all \
             --format '%{window-id}|%{app-bundle-id}|%{workspace}|%{window-title}')"

echo "$checked Fenster geprüft, $moved verschoben."

# ── Aufräumen ─────────────────────────────────────────────────────────
sleep 0.4
for w in 1 2 3 4 5 6 7; do
  "$AERO" flatten-workspace-tree --workspace "$w" 2>/dev/null
  "$AERO" layout --workspace "$w" --root h_tiles 2>/dev/null
  "$AERO" balance-sizes --workspace "$w" 2>/dev/null
done

# Workspace 2 braucht die verschachtelte dritte Spalte (Raindrop ⁄ Reader).
# Das flatten oben löst sie auf, deshalb hier wieder aufbauen.
rmdir "$LOCKDIR" 2>/dev/null; trap - EXIT
"$HERE/discover-layout.sh" 2>/dev/null | tail -6

notify "Layouts gerichtet — $moved Fenster verschoben"
