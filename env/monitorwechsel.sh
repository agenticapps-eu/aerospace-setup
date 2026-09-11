#!/usr/bin/env bash
# @group: Aufbauen
# @label: Monitorwechsel verarbeiten
# @key:   alt-ctrl-w
# ══════════════════════════════════════════════════════════════════════
# MONITORWECHSEL · nach dem An- oder Abstecken  Hotkey: alt-ctrl-w
#
# WARUM ES DAS BRAUCHT:
# AeroSpace zieht die Monitorzuordnung beim Hotplug nicht von selbst
# nach. Die Fenster bleiben liegen, wo sie waren — es sieht nach
# kaputtem Layout aus, obwohl `list-windows` schon alles korrekt meldet
# (AeroSpace-Issues #520, #651). Ein reload-config richtet es.
#
# WARUM ES KEINEN MODUSWAHLSCHALTER GIBT:
# Die Verteilung steht deklarativ in workspace-to-monitor-force-
# assignment, als Array mit Rückfallebene:
#     1 = ['lg', 'built-in', 'main']
# Erste passende Regel gewinnt. Ein Monitor, zwei Monitore, nur der
# eingebaute Schirm — alle drei Fälle sind damit schon beschrieben.
# Ein umschaltbarer Zustand wäre eine zweite Wahrheit daneben, und zwei
# Wahrheiten laufen auseinander. Dieses Skript schaltet deshalb nichts
# um, es sagt AeroSpace nur: schau nochmal hin.
#
# Funktioniert in BEIDE Richtungen — an- wie abgesteckt.
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

monitore="$("$AERO" list-monitors --format '%{monitor-name}' 2>/dev/null)"
anzahl="$(printf '%s\n' "$monitore" | grep -c .)"

# 1 · Zuordnung neu auswerten. Das allein behebt den Hotplug-Fall.
"$AERO" reload-config 2>&1 | grep -i error && echo "warn: Config meckert" >&2
sleep 0.5

# 2 · Fenster an ihren Platz. Öffnet nichts, beendet nichts.
#     Erst nach dem Reload, sonst sortiert es gegen eine veraltete
#     Monitorzuordnung.
rmdir "$LOCKDIR" 2>/dev/null; trap - EXIT
"$HERE/relayout.sh" >/dev/null 2>&1

liste="$(printf '%s' "$monitore" | tr '\n' ',' | sed 's/,$//;s/,/, /g')"
if [ "$anzahl" -eq 1 ]; then
  notify "Ein Monitor ($liste) — alle Workspaces darauf"
else
  notify "$anzahl Monitore ($liste) — Zuordnung neu gesetzt"
fi
