#!/usr/bin/env bash
# @group: Terminals
# @label: cmux hermes + homelab → 5
# @key:   alt-ctrl-5
# ══════════════════════════════════════════════════════════════════════
# cmux · die beiden Remote-Sitzungen            Hotkey: alt-ctrl-5
#
#   hermes   herdr auf dem VPS
#   homelab  herdr auf dem NAS
#
# EIN Fenster mit zwei cmux-Workspaces, nicht zwei Fenster. cmux zeichnet
# seine vertikalen Tabs selbst; gemessen am 18.09.2026 bleibt es bei einem
# Fenster, egal wie viele Workspaces offen sind. Genau deshalb ersetzt es
# hier die zwei Ghostty-Fenster: die waren native macOS-Tabs und damit eine
# stete Reibungsquelle mit AeroSpace.
#
# VORAUSSETZUNG: cmux laesst seinen Steuer-Socket standardmaessig nur von
# Prozessen ansprechen, die aus cmux selbst kommen. Fuer dieses Skript muss
# in ~/.config/cmux/cmux.json stehen:
#
#   "automation": { "socketControlMode": "password", "socketPassword": "…" }
#
# und dasselbe Passwort hier in env/hosts.conf als CMUX_SOCKET_PASSWORD.
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -f "$HERE/hosts.conf" ] && source "$HERE/hosts.conf"
HERMES_HOST="${HERMES_HOST:-hermes}"
NAS_HOST="${NAS_HOST:-ugreen}"
export CMUX_SOCKET_PASSWORD="${CMUX_SOCKET_PASSWORD:-}"

[ -d /Applications/cmux.app ] || { echo "cmux ist nicht installiert."; exit 1; }
command -v cmux >/dev/null || { echo "cmux-CLI nicht im PATH."; exit 1; }

# App starten und auf den Socket warten. `cmux ping` ist der einzige
# verlaessliche Bereitschaftstest — die App braucht nach dem Start einen
# Moment, bis sie zuhoert.
open -a cmux
for i in $(seq 1 40); do
  cmux ping >/dev/null 2>&1 && break
  sleep 0.25
done
if ! cmux ping >/dev/null 2>&1; then
  echo "cmux antwortet nicht auf dem Socket."
  echo "Pruefen: cmux settings path  →  automation.socketControlMode"
  exit 1
fi

# Vorhandene Workspaces nicht verdoppeln.
existing="$(cmux workspace list 2>/dev/null || true)"

# start <name> <host-muster> <befehl…>
#
# ZWEI WEGE, und der zweite ist kein Schmuck: `new-workspace --command`
# hat am 18.09.2026 bei hermes gegriffen und bei homelab nicht — der
# Workspace stand da, aber mit blanker Shell. Deshalb wird nachgesehen, ob
# die Sitzung wirklich laeuft, und notfalls der Befehl in die Oberflaeche
# geschickt. `send` braucht das Ziel als --surface bzw. --workspace; als
# Positionsargument wird es als TEXT gewertet und landet im gerade
# ausgewaehlten Workspace. Genau das ist mir einmal passiert.
start() {
  local name="$1" pattern="$2"; shift 2
  local cmd="$*" ref i

  case "$existing" in
    *"$name"*) echo "  $name gibt es schon"; ;;
    *)
      cmux new-workspace --name "$name" --command "$cmd" >/dev/null 2>&1 \
        || { echo "  warn: $name liess sich nicht anlegen"; return 0; }
      sleep 1.5 ;;
  esac

  # Laeuft die Sitzung? Bis zu 10 s warten.
  for i in $(seq 1 20); do
    pgrep -f "herdr --remote $pattern" >/dev/null 2>&1 && { echo "  $name laeuft"; return 0; }
    sleep 0.5
  done

  # Nachfassen: Befehl in die Oberflaeche des Workspace tippen.
  ref="$(cmux workspace list 2>/dev/null | awk -v n="$name" '$NF==n || $0 ~ ("  "n"$") {print $1; exit}' | tr -d '*')"
  [ -z "$ref" ] && { echo "  warn: $name nicht gefunden"; return 0; }
  cmux send --workspace "$ref" -- "$cmd\n" >/dev/null 2>&1
  for i in $(seq 1 20); do
    pgrep -f "herdr --remote $pattern" >/dev/null 2>&1 && { echo "  $name nachgestartet"; return 0; }
    sleep 0.5
  done
  echo "  warn: $name antwortet nicht"
}

echo "▸ cmux-Workspaces:"
start hermes  "$HERMES_HOST"  "herdr --remote $HERMES_HOST --session hermes"
start homelab "$NAS_HOST"     "herdr --remote $NAS_HOST --session homelab"

sleep 1
"$AERO" workspace 5 2>/dev/null
notify "cmux: hermes + homelab"
