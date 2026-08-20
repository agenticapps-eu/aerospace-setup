#!/usr/bin/env bash
# @group: Aufbauen
# @label: Layouts richten
# @key:   alt-ctrl-r
# ══════════════════════════════════════════════════════════════════════
# RELAYOUT — richtet die Layouts auf 2 und 5            Hotkey: alt-ctrl-r
#
#   Workspace 2 (DISCOVER, Odyssey)
#     Zen │ Claude │ Raindrop │ Reader     (vier gleiche Spalten)
#
#   Workspace 3 (WORK, Odyssey)
#     Dia │ Slack │ Google Meet          (drei gleiche Drittel)
#
# Nutze das, wenn ein Layout verrutscht ist — es öffnet keine Apps,
# sondern ordnet nur die bereits offenen Fenster.
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"

ZEN=app.zen-browser.zen
CLAUDE=com.anthropic.claudefordesktop
RAINDROP=io.raindrop.macapp
READER=io.readwise.read
DIA=company.thebrowser.dia
SLACK=com.tinyspeck.slackmacgap
# Google Meet ist eine Chrome-PWA und meldet sich als com.google.Chrome.
# Nur am Titel unterscheidbar — echte Chrome-Fenster enden auf
# "- Google Chrome", PWA-Fenster nicht.
CHROME=com.google.Chrome
MEET_TITLE='Google Meet'

# ── Workspace 2 · DISCOVER ────────────────────────────────────────────
# Erst plattmachen und in eine Reihe bringen, dann die letzten zwei
# Spalten zu einer vertikal geteilten Spalte zusammenfassen.
"$AERO" flatten-workspace-tree --workspace 2 2>/dev/null
"$AERO" layout --workspace 2 --root h_tiles 2>/dev/null

# Ohne --focus-follows-window: die Reihenfolge ist ohnehin nicht
# erzwingbar, und der Fokus soll nicht herumspringen.
for b in "$ZEN" "$CLAUDE" "$RAINDROP" "$READER"; do
  while read -r id; do
    [ -n "$id" ] && "$AERO" move-node-to-workspace --window-id "$id" 2
  done <<< "$(ids "$b")"
done
"$AERO" balance-sizes --workspace 2 2>/dev/null

# Reader unter Raindrop schieben → gemeinsamer Container → vertikal


# ── Workspace 3 · WORK ────────────────────────────────────────────────
"$AERO" flatten-workspace-tree --workspace 3 2>/dev/null
"$AERO" layout --workspace 3 --root h_tiles 2>/dev/null
for b in "$DIA" "$SLACK"; do
  while read -r id; do
    [ -n "$id" ] && "$AERO" move-node-to-workspace --window-id "$id" 3 --focus-follows-window
  done <<< "$(ids "$b")"
done
# Meet gezielt über den Titel holen, damit die Chrome-Fenster auf 6 bleiben
while read -r id; do
  [ -n "$id" ] && "$AERO" move-node-to-workspace --window-id "$id" 3 --focus-follows-window
done <<< "$(ids_titled "$CHROME" "$MEET_TITLE")"
"$AERO" balance-sizes --workspace 3 2>/dev/null

# ── Die einfachen Hälften: 1 (LG), 3 Productivity, 4 Communication ────
tidy 1 4 7

echo
layout_report 2 3
notify "Layout gerichtet"
