#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════
# Mission-Control-Tastenkürzel abschalten / zurückholen
#
#   ./mission-control-keys.sh status     zeigt den Ist-Zustand
#   ./mission-control-keys.sh dry-run    zeigt, was passieren WÜRDE
#   ./mission-control-keys.sh off        schaltet ctrl+Pfeile ab (mit Backup)
#   ./mission-control-keys.sh on         schaltet sie wieder ein
#   ./mission-control-keys.sh restore    stellt das Backup 1:1 wieder her
#
# Betroffen sind genau diese acht Kürzel:
#   ctrl-←  ctrl-→          Space links / rechts        (ID 79 / 81)
#   ctrl-shift-←  -→        Fenster auf Space links/rechts (80 / 82)
#   ctrl-↑                  Mission Control             (32)
#   ctrl-↓                  Programmfenster / App Exposé (33)
#   ctrl-shift-↑  -↓        dieselben mit shift          (34 / 35)
#
# Mission Control selbst wird NICHT abgeschaltet — nur die Tastenkürzel.
# Du erreichst es weiter über F3 und den Drei-Finger-Wisch nach oben.
#
# Dasselbe geht per Klick: Systemeinstellungen → Tastatur →
# Tastaturkurzbefehle → Mission Control. Das Skript ist nur schneller
# und macht ein Backup.
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail

IDS=(32 33 34 35 79 80 81 82)
DOMAIN=com.apple.symbolichotkeys
BACKUP_DIR="$HOME/.local/state/aerospace/backups"
BACKUP="$BACKUP_DIR/symbolichotkeys-backup.plist"
ACTIVATE=/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings

label() {
  case "$1" in
    32) echo "ctrl-↑          Mission Control" ;;
    33) echo "ctrl-↓          Programmfenster / App Exposé" ;;
    34) echo "ctrl-shift-↑    Mission Control (shift)" ;;
    35) echo "ctrl-shift-↓    Programmfenster (shift)" ;;
    79) echo "ctrl-←          Space links" ;;
    80) echo "ctrl-shift-←    Fenster auf Space links" ;;
    81) echo "ctrl-→          Space rechts" ;;
    82) echo "ctrl-shift-→    Fenster auf Space rechts" ;;
  esac
}

show_status() {
  printf "%-4s %-6s %s\n" "ID" "AN?" "KÜRZEL"
  printf -- "----------------------------------------------\n"
  for id in "${IDS[@]}"; do
    en=$(python3 - "$id" <<'PY'
import subprocess,plistlib,sys,os
p=os.path.expanduser("~/Library/Preferences/com.apple.symbolichotkeys.plist")
raw=subprocess.run(["plutil","-convert","xml1","-o","-",p],capture_output=True).stdout
hk=plistlib.loads(raw).get("AppleSymbolicHotKeys",{})
e=hk.get(sys.argv[1],{}).get("enabled")
print("an" if e else ("aus" if e is not None else "?"))
PY
)
    printf "%-4s %-6s %s\n" "$id" "$en" "$(label "$id")"
  done
}

set_all() {           # $1 = true|false, $2 = dry-run?
  local want="$1" dry="${2:-}"
  for id in "${IDS[@]}"; do
    # Original-Parameter auslesen und unverändert zurückschreiben —
    # nur `enabled` wird gekippt. So geht keine Tastenzuordnung verloren.
    xml=$(python3 - "$id" "$want" <<'PY'
import subprocess,plistlib,sys,os
kid,want=sys.argv[1],sys.argv[2]=="true"
p=os.path.expanduser("~/Library/Preferences/com.apple.symbolichotkeys.plist")
raw=subprocess.run(["plutil","-convert","xml1","-o","-",p],capture_output=True).stdout
hk=plistlib.loads(raw).get("AppleSymbolicHotKeys",{})
e=hk.get(kid)
if not e: sys.exit(1)
par=(e.get("value") or {}).get("parameters") or []
ints="".join(f"<integer>{int(v)}</integer>" for v in par)
print(f"<dict><key>enabled</key><{'true' if want else 'false'}/>"
      f"<key>value</key><dict><key>parameters</key><array>{ints}</array>"
      f"<key>type</key><string>standard</string></dict></dict>")
PY
) || { echo "  ID $id: kein Eintrag, übersprungen"; continue; }
    if [ "$dry" = "dry" ]; then
      echo "  würde setzen: ID $id enabled=$want   ($(label "$id"))"
    else
      defaults write "$DOMAIN" AppleSymbolicHotKeys -dict-add "$id" "$xml"
      echo "  ID $id enabled=$want   ($(label "$id"))"
    fi
  done
  if [ "$dry" != "dry" ]; then
    [ -x "$ACTIVATE" ] && "$ACTIVATE" -u 2>/dev/null
    echo
    echo "Fertig. Falls ein Kürzel noch reagiert: ab- und wieder anmelden."
  fi
}

backup() {
  mkdir -p "$BACKUP_DIR"
  defaults export "$DOMAIN" "$BACKUP"
  echo "Backup: $BACKUP"
}

case "${1:-status}" in
  status)  show_status ;;
  dry-run) echo "TROCKENLAUF — es wird nichts geändert."; echo; set_all false dry ;;
  off)     backup; echo; echo "Schalte ab:"; set_all false ;;
  on)      echo "Schalte ein:"; set_all true ;;
  restore)
    [ -f "$BACKUP" ] || { echo "Kein Backup unter $BACKUP"; exit 1; }
    defaults import "$DOMAIN" "$BACKUP"
    [ -x "$ACTIVATE" ] && "$ACTIVATE" -u 2>/dev/null
    echo "Backup wiederhergestellt. Ggf. ab- und wieder anmelden." ;;
  *) echo "Unbekannt: $1"; sed -n '4,12p' "$0"; exit 1 ;;
esac
