#!/usr/bin/env bash
# @group: Aufbauen
# @label: Alles aufbauen
# @key:   alt-ctrl-a
# ══════════════════════════════════════════════════════════════════════
# BUILD ALL — das komplette Setup aufbauen          Hotkey: alt-ctrl-a
#
#   LG oben          1 DEV            Ghostty (herdr) │ Obsidian
#   Odyssey unten    2 DISCOVER       Zen │ Claude │ Raindrop ⁄ Reader
#                    3 WORK           Dia │ Slack │ Google Meet
#                    4 COMMUNICATION  WhatsApp │ Fastmail
#                    5 REMOTE         Ghostty: hermes │ homelab (NAS)
#                    6 TOOLS          Ghostty: Terminal │ Chrome
#                    7 PRODUCTIVITY   ForkLift │ Superlist
#
# Einmal morgens. Erster Lauf 30–60 s, weil Electron-Apps langsam sind.
# Danach ist alles offen und relayout.sh (alt-ctrl-r) reicht.
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

# Der Lock aus _lib.sh würde die Unterskripte blockieren — hier freigeben
# und selbst verwalten.
rmdir "$LOCKDIR" 2>/dev/null; trap - EXIT

# Ghostty zuerst komplett beenden: alte macOS-Tab-Gruppen lösen sich
# nicht von selbst auf, und Reste würden sich wieder verschmelzen.
echo "▸ Ghostty zurücksetzen …"
ghostty_reset

echo "▸ Ghostty: herdr lokal (1), Remote (5), Terminal (6) …"
"$HERE/ghostty-herdr.sh"
"$HERE/ghostty-remote.sh"
"$HERE/ghostty-tools.sh"

echo "▸ LG: Workspace 1 (Dev) …"
open_in md.obsidian                 1

echo "▸ Odyssey: Workspace 2 (Discover) …"
# Vier gleiche Spalten, deterministisch. Die vertikal geteilte dritte
# Spalte habe ich rausgenommen: sie hing an der Annahme, dass sich die
# Fenster in Aufrufreihenfolge von links nach rechts einreihen. Das tun
# sie nicht — dadurch landete Reader unter CLAUDE statt unter Raindrop.
# Wenn du die Teilung willst: Reader fokussieren, alt-shift-minus, alt-b.
open_in app.zen-browser.zen            2
open_in com.anthropic.claudefordesktop 2
open_in io.raindrop.macapp             2
open_in io.readwise.read               2
tidy 2


echo "▸ Odyssey: Workspace 4 (Communication) und 7 (Productivity) …"
open_in net.whatsapp.WhatsApp       4
open_in com.fastmail.mac.Fastmail   4
open_in com.binarynights.ForkLift   7
open_in com.superlist.superlist     7

echo "▸ Odyssey: Workspace 3 (Work) …"
place_one company.thebrowser.dia    3
place_one com.tinyspeck.slackmacgap 3
# Google Meet ist eine Chrome-PWA (com.google.Chrome) — nur am Titel zu
# treffen, sonst würden die Chrome-Fenster von 6 mitwandern.
while read -r id; do
  [ -n "$id" ] && "$AERO" move-node-to-workspace --window-id "$id" 3 --focus-follows-window
done <<< "$(ids_titled com.google.Chrome 'Google Meet')"
"$AERO" balance-sizes --workspace 3 2>/dev/null

echo "▸ Hälften richten …"
tidy 1 4 7

# Fokus: unten Discover, oben Dev
show 2 1

echo
layout_report 1 2 3 4 5 6 7
notify "Setup aufgebaut — 7 Workspaces"
