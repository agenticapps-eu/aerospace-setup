#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════
# gt — EIN Ghostty-Fenster für EINEN Zweck
#
#   ./gt.sh herdr      herdr lokal            → Workspace 1
#   ./gt.sh hermes     herdr auf dem VPS      → Workspace 5
#   ./gt.sh homelab    herdr auf dem NAS      → Workspace 5
#   ./gt.sh term       normales zsh           → Workspace 6
#   ./gt.sh btop       Systemmonitor          → Workspace 6
#   ./gt.sh spf        superfile              → Workspace 6
#
#   ./gt.sh herdr 2    zweites Argument überschreibt den Workspace
#
# WARUM KEINE TABS MEHR:
# Ghostty benutzt auf macOS native Tabs, und native Tabs sind in
# Wirklichkeit einzelne NSWindows, die macOS zu einer Gruppe bündelt.
# AeroSpace kachelt einzelne Mitglieder dieser Gruppe — macOS reisst sie
# dabei aus der Gruppe. Ergebnis: beim Tab-Klick tauchen scheinbar neue
# Fenster auf, und Gruppen verschmelzen unkontrolliert.
#
# Deshalb: ein Fenster pro Zweck. Umgeschaltet wird mit AeroSpace
# (alt-1..6, ctrl-←/→, alt-←/→), nicht mit Ghostty-Tabs.
#
# Zusätzlich ist AppleWindowTabbingMode auf "manual" gesetzt, sonst
# klebt macOS jedes neue Fenster als Tab an ein bestehendes:
#   defaults write -g AppleWindowTabbingMode -string manual
#   defaults delete -g AppleWindowTabbingMode     # zurücknehmen
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"

# ── SSH-Ziele ─────────────────────────────────────────────────────────
# Die Ziele stehen NICHT hier im Repo, sondern in env/hosts.conf — einer
# lokalen Datei, die .gitignore ausschliesst. Vorlage: hosts.conf.example.
#
# Am besten trägst du dort SSH-Aliase ein, keine IPs: Aliase stehen in
# ~/.ssh/config zusammen mit User, Port und Key, und wenn sich eine
# Adresse ändert, gibt es genau eine Stelle zum Nachziehen.
[ -f "$(dirname "$0")/hosts.conf" ] && source "$(dirname "$0")/hosts.conf"
HERMES_HOST="${HERMES_HOST:-hermes}"
NAS_HOST="${NAS_HOST:-ugreen}"

HERE="$(cd "$(dirname "$0")" && pwd)"
RUNNER="$HERE/gt-run.sh"

# Jedes Fenster bekommt einen Titel mitgegeben — sonst heissen alle
# "Oh hello, Ghostty" und sind nicht auseinanderzuhalten. Der Titel wird
# von gt-run.sh per ANSI-Escape gesetzt, bevor das Programm startet.
profile="${1:-}"
case "$profile" in
  # --session: herdr hält die Sitzung auf der Gegenstelle am Leben. Bricht
  #   die Verbindung ab, läuft dort alles weiter und der nächste Aufruf
  #   hängt sich wieder dran, statt bei null anzufangen.
  # --retry:   siehe gt-run.sh — kurze Netzhänger heilen von selbst, und
  #   das Fenster stirbt nicht mit der Verbindung.
  # hermes und homelab sind am 18.09.2026 nach cmux umgezogen (homelab.sh),
  # der Mac mini nach iTerm (it.sh). Ghostty bleibt fuer herdr lokal und
  # fuer die Werkzeuge, die man ab und zu von Hand aufmacht.
  herdr)   ws="${2:-1}"; args="herdr herdr" ;;
  term)    ws="${2:-6}"; args="terminal" ;;
  btop)    ws="${2:-6}"; args="btop btop" ;;
  spf)     ws="${2:-6}"; args="superfile spf" ;;
  *)
    sed -n '4,12p' "$0" | sed 's/^# \{0,1\}//'
    exit 1 ;;
esac

if [ -z "${2:-}" ] && [ "$(python3 "$HERE/layout.py" mode)" = laptop ]; then
  case "$profile" in herdr) ws=1 ;; hermes) ws=2 ;; homelab) ws=3 ;; *) ws=7 ;; esac
fi

# Keine Anführungszeichen nötig: Ghostty bekommt Pfad + einfache Wörter.
ghostty_window "$ws" "$profile" "$RUNNER $args"
