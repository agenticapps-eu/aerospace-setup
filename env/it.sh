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

# Laeuft schon eine Sitzung? Dann nur hinspringen statt eine zweite oeffnen.
if [ -n "$("$AERO" list-windows --monitor all --app-bundle-id com.googlecode.iterm2 --format '%{window-id}' 2>/dev/null)" ]; then
  echo "iTerm laeuft bereits — kein zweites Fenster."
  "$AERO" workspace 1 2>/dev/null
  exit 0
fi

# --session: herdr haelt die Sitzung auf dem Mac mini am Leben. Bricht die
#   Verbindung ab, laeuft dort alles weiter und der naechste Aufruf haengt
#   sich wieder dran.
# --retry:   siehe gt-run.sh — kurze Netzhaenger heilen von selbst, und das
#   Fenster stirbt nicht mit der Verbindung.
RUNNER="$HERE/gt-run.sh"
CMD="$RUNNER macmini --retry herdr --remote $MACMINI_HOST --session macmini"

osascript <<APPLESCRIPT >/dev/null 2>&1
tell application "iTerm"
  create window with default profile command "$CMD"
end tell
APPLESCRIPT

sleep 1.5
"$AERO" workspace 1 2>/dev/null
notify "iTerm: herdr auf dem Mac mini"
echo "iTerm → Workspace 1 ($MACMINI_HOST)"
