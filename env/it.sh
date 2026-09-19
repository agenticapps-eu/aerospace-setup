#!/usr/bin/env bash
# @group: Terminals
# @label: iTerm herdr Mac mini → 1
# @key:   alt-ctrl-3
# ══════════════════════════════════════════════════════════════════════
# iTerm2 · herdr auf dem Mac mini                  Hotkey: alt-ctrl-3
#
# WARUM iTerm UND NICHT GHOSTTY: Ghostty benutzt auf macOS native Tabs —
# das sind eigenstaendige Fenster in einer Gruppe, und genau daran reibt
# sich AeroSpace. iTerm zeichnet seine Tabs selbst. Gemessen am
# 18.09.2026: ein iTerm-Fenster mit zwei Tabs, AeroSpace zaehlt EIN
# Fenster. Damit ist die ganze Titel- und Fensterakrobatik hier unnoetig.
#
# Der Fenstertitel folgt dem laufenden Befehl; fuer die Zuordnung reicht
# die Bundle-ID, weil auf Workspace 1 nur dieses eine iTerm-Fenster steht.
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -f "$HERE/hosts.conf" ] && source "$HERE/hosts.conf"
MACMINI_HOST="${MACMINI_HOST:-mac-mini}"

[ -d /Applications/iTerm.app ] || { echo "iTerm2 ist nicht installiert."; exit 1; }

# Laeuft die SITZUNG schon? Nicht: laeuft irgendein iTerm-Fenster.
#
# Der Unterschied hat mich am 18.09.2026 zweimal erwischt: iTerm oeffnet
# beim Aktivieren von sich aus ein leeres Fenster, und die alte Pruefung
# hielt das faelschlich fuer „alles da" und tat nichts. Gepruef wird
# deshalb der herdr-Prozess zum Ziel-Host.
if pgrep -f "herdr --remote $MACMINI_HOST" >/dev/null 2>&1; then
  echo "macmini-Sitzung laeuft bereits."
  "$AERO" workspace 1 2>/dev/null
  exit 0
fi

# --session default: AUSDRUECKLICH die Default-Sitzung des Mac mini.
#   Ohne das Flag leitet herdr den Sitzungsnamen aus dem SSH-Ziel ab und
#   erzeugt "macmini" — eine Sitzung, deren Server beim Attach ueber SSH
#   startet und damit ausserhalb der Aqua-Sitzung liegt. Claude Code kommt
#   dort nicht an den Schluesselbund und meldet "Not logged in".
#   Die Default-Sitzung gehoert dem LaunchAgent dev.herdr.server auf dem
#   Mac mini, laeuft also in der GUI-Sitzung; ihre Panes erben das.
# --retry:   siehe gt-run.sh — kurze Netzhaenger heilen von selbst, und das
#   Fenster stirbt nicht mit der Verbindung.
RUNNER="$HERE/gt-run.sh"
CMD="$RUNNER macmini --retry herdr --remote $MACMINI_HOST --session default"

# Profil "Ghostty-Look" liegt als Dynamic Profile unter
# ~/Library/Application Support/iTerm2/DynamicProfiles/aerospace.json —
# Catppuccin Mocha, FiraCode Nerd Font Mono 16, Transparenz und Blur wie
# in Ghostty. iTerm liest die Datei im laufenden Betrieb neu ein.
# Faellt das Profil aus, nimmt AppleScript das Standardprofil.
osascript <<APPLESCRIPT >/dev/null 2>&1
tell application "iTerm"
  try
    create window with profile "Ghostty-Look" command "$CMD"
  on error
    create window with default profile command "$CMD"
  end try
end tell
APPLESCRIPT

sleep 1.5
"$AERO" workspace 1 2>/dev/null
notify "iTerm: herdr auf dem Mac mini"
echo "iTerm → Workspace 1 ($MACMINI_HOST)"
