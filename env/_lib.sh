#!/usr/bin/env bash
# Gemeinsame Helfer. Wird per `source` eingebunden, nicht direkt aufgerufen.

set -uo pipefail

AERO="$(command -v aerospace || true)"
[ -x "$AERO" ] || AERO=/opt/homebrew/bin/aerospace
[ -x "$AERO" ] || AERO=/usr/local/bin/aerospace
[ -x "$AERO" ] || { osascript -e 'display notification "aerospace CLI nicht gefunden" with title "AeroSpace"'; exit 1; }

GHOSTTY_BID=com.mitchellh.ghostty
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── read_layout [datei] ───────────────────────────────────────────────
# Liest die Soll-Tabelle in vier parallele Arrays:
#   r_bundle  r_ws  r_title  r_auto
#
# Parallele Arrays statt `declare -A`, weil macOS bash 3.2 mitbringt —
# und weil die REIHENFOLGE bedeutungstragend ist: erste Übereinstimmung
# gewinnt, wie bei on-window-detected. Ein assoziatives Array hätte die
# Reihenfolge verloren und damit die Titelregeln entwertet.
#
# Ein `+` vor der Bundle-ID heisst: beim Aufbau (build-all.sh) öffnen.
r_bundle=(); r_ws=(); r_title=(); r_auto=()
read_layout() {
  local conf="${1:-$LIB_DIR/layout.conf}" line b w t
  r_bundle=(); r_ws=(); r_title=(); r_auto=()
  [ -f "$conf" ] || { echo "Soll-Tabelle fehlt: $conf" >&2; return 1; }
  while IFS= read -r line; do
    line="${line%%#*}"
    [ -z "${line// /}" ] && continue
    read -r b w t <<< "$line"
    [ -z "$b" ] && continue
    case "$b" in
      +*) r_auto+=("ja");   b="${b#+}" ;;
      *)  r_auto+=("nein") ;;
    esac
    r_bundle+=("$b"); r_ws+=("$w"); r_title+=("$t")
  done < "$conf"
  return 0
}

# mkdir ist atomar — verhindert zwei parallele Aufbauten.
LOCKDIR=/tmp/aerospace-env.lock
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  if [ -n "$(find "$LOCKDIR" -maxdepth 0 -mmin +2 2>/dev/null)" ]; then
    rmdir "$LOCKDIR" 2>/dev/null && mkdir "$LOCKDIR" 2>/dev/null
  else
    osascript -e 'display notification "Aufbau läuft bereits" with title "AeroSpace"' >/dev/null 2>&1
    exit 0
  fi
fi
trap 'rmdir "$LOCKDIR" 2>/dev/null' EXIT

notify() { osascript -e "display notification \"$1\" with title \"AeroSpace\"" >/dev/null 2>&1 || true; }

# ── sh_wrap <befehl> ──────────────────────────────────────────────────
# Ghostty führt `command` OHNE Login-Shell aus. herdr liegt in
# ~/.local/bin, spf in /usr/local/bin, btop in /opt/homebrew/bin — ohne
# Login-Shell fehlt der PATH. Deshalb alles durch zsh -lc schicken.
# Einfache Anführungszeichen innen, damit der AppleScript-String
# (Doppelquotes) nicht bricht.
sh_wrap() { printf "/bin/zsh -lc '%s'" "$1"; }

# ── ghostty_window <ziel-workspace> <label> <cmd1> [cmd2] [cmd3] ───────
# Erzeugt EIN Ghostty-Fenster mit einem Tab pro Befehl und schiebt es in
# den Zielworkspace. Gibt die AeroSpace-Fenster-ID aus.
#
# Erkennung des neuen Fensters über Snapshot-Differenz: alle Ghostty-
# Fenster teilen dieselbe Bundle-ID, es gibt also keinen anderen Weg,
# das gerade erzeugte zu identifizieren.
#
# Die Tabs entstehen über Ghostty's AppleScript-Dictionary
# (`new window` / `new tab in <w>` mit einer `surface configuration`,
# die ein `command` trägt). Kein Tastatur-Simulieren, keine Sleeps
# zwischen den Tabs — jeder Tab bekommt seinen Befehl beim Erzeugen.
ghostty_window() {
  local ws="$1" label="$2"; shift 2

  # ZIELWORKSPACE ZUERST FOKUSSIEREN. Neue Fenster entstehen im gerade
  # fokussierten Workspace — damit entfällt das Verschieben danach.
  #
  # Vorher habe ich das neue Fenster per Snapshot-Differenz gesucht und
  # dann verschoben. Das lief in eine Race Condition gegen die
  # on-window-detected-Regel für Ghostty: die Regel schob das Fenster
  # nach 1, mein move schob es woandershin, und je nach Reihenfolge
  # gewann die Regel. Ergebnis waren Fenster auf dem falschen Workspace.
  # Die Regel ist deshalb aus der Config entfernt.
  "$AERO" workspace "$ws" 2>/dev/null
  sleep 0.3

  local script="tell application \"Ghostty\"
  set cfg1 to new surface configuration
  set command of cfg1 to \"$1\"
  set wait after command of cfg1 to true
  set w to new window with configuration cfg1"
  local n=2
  shift
  for c in "$@"; do
    script="$script
  set cfg$n to new surface configuration
  set command of cfg$n to \"$c\"
  set wait after command of cfg$n to true
  new tab in w with configuration cfg$n"
    n=$((n+1))
  done
  script="$script
end tell"

  # KEIN `activate`. Das holt Ghostty in den Vordergrund und AeroSpace
  # folgt dem fokussierten Fenster — womöglich auf einen anderen
  # Workspace. Genau dadurch entstanden die verirrten Fenster.
  osascript -e "$script" >/dev/null 2>&1 \
    || { echo "warn: $label — AppleScript fehlgeschlagen" >&2; return 1; }

  sleep 0.8      # Ghostty braucht einen Moment, bis das Fenster steht
  echo "$label → Workspace $ws"
}

# ── ghostty_close_all ─────────────────────────────────────────────────
# `close every window` versteht Ghostty's Dictionary nicht (-1708),
# deshalb einzeln in einer Schleife.
ghostty_close_all() {
  pgrep -x ghostty >/dev/null || return 0
  osascript -e 'tell application "Ghostty"
    repeat with i from (count of windows) to 1 by -1
      try
        close window i
      end try
    end repeat
  end tell' >/dev/null 2>&1
  sleep 1
  local n
  n="$(ids "$GHOSTTY_BID" | wc -l | tr -d ' ')"
  echo "Ghostty-Fenster übrig: $n"
}

# ── ghostty_reset ─────────────────────────────────────────────────────
# Beendet Ghostty komplett. Nötig, weil bestehende macOS-Tab-Gruppen
# nicht nachträglich aufgelöst werden: AppleWindowTabbingMode=manual gilt
# nur für NEU erzeugte Fenster. Ohne Reset bleibt eine alte Gruppe mit
# mehreren Tabs erhalten und AeroSpace kämpft weiter mit ihr.
ghostty_reset() {
  pgrep -x ghostty >/dev/null || return 0
  osascript -e 'quit app "Ghostty"' >/dev/null 2>&1
  local i
  for i in $(seq 1 40); do
    pgrep -x ghostty >/dev/null || { echo "Ghostty beendet"; sleep 0.5; return 0; }
    sleep 0.25
  done
  echo "warn: Ghostty läuft noch — bitte von Hand mit cmd-q beenden" >&2
}

# ── ids <bundle-id> ───────────────────────────────────────────────────
# Alle AeroSpace-Fenster-IDs einer App, eine pro Zeile.
#
# ACHTUNG: `--all` ist ein Alias für `--monitor all` und kollidiert mit
# Filter-Flags wie --app-bundle-id ("--all conflicts with filtering
# flags"). Deshalb hier explizit `--monitor all`. Mit --all lief die
# Funktion still ins Leere und alles landete in "nicht gefunden".
ids() {
  "$AERO" list-windows --monitor all --app-bundle-id "$1" \
          --format '%{window-id}' 2>/dev/null
}

# ── ids_titled <bundle-id> <titel-regex> ──────────────────────────────
# Fenster-IDs einer App, gefiltert nach Fenstertitel. Nötig für Apps, die
# sich eine Bundle-ID teilen — Google Meet ist eine Chrome-PWA und meldet
# sich als com.google.Chrome, ist also nur am Titel zu erkennen.
ids_titled() {
  "$AERO" list-windows --monitor all --app-bundle-id "$1" \
          --format '%{window-id}|%{window-title}' 2>/dev/null \
    | grep -Ei "\|.*$2" | cut -d'|' -f1
}

# ── ids_untitled <bundle-id> <titel-regex> ────────────────────────────
# Umgekehrt: alle Fenster der App, deren Titel NICHT passt.
ids_untitled() {
  "$AERO" list-windows --monitor all --app-bundle-id "$1" \
          --format '%{window-id}|%{window-title}' 2>/dev/null \
    | grep -Eiv "\|.*$2" | cut -d'|' -f1
}

# ── open_in <bundle-id> <workspace> ───────────────────────────────────
# App starten (falls nötig), auf ihr Fenster warten, ALLE ihre Fenster in
# den Zielworkspace schieben. Explizit per --window-id, damit eine Szene
# die on-window-detected-Defaults überschreiben kann.
open_in() {
  local bid="$1" ws="$2" got="" i
  open -b "$bid" >/dev/null 2>&1 || { echo "warn: $bid startet nicht" >&2; return 0; }
  for i in $(seq 1 60); do
    got="$(ids "$bid")"; [ -n "$got" ] && break
    sleep 0.25
  done
  [ -z "$got" ] && { echo "warn: kein Fenster für $bid" >&2; return 0; }
  while read -r id; do
    [ -n "$id" ] && "$AERO" move-node-to-workspace --window-id "$id" "$ws"
  done <<< "$got"
}

# ── place_one <bundle-id> <workspace> ─────────────────────────────────
# Wie open_in, schiebt aber die Fenster einzeln und lässt den Fokus
# mitwandern. Dadurch reihen sich die Fenster in Aufrufreihenfolge von
# links nach rechts ein — wichtig für Workspace 4 und 5.
place_one() {
  local bid="$1" ws="$2" got="" i
  open -b "$bid" >/dev/null 2>&1 || { echo "warn: $bid startet nicht" >&2; return 0; }
  for i in $(seq 1 60); do
    got="$(ids "$bid")"; [ -n "$got" ] && break
    sleep 0.25
  done
  [ -z "$got" ] && { echo "warn: kein Fenster für $bid" >&2; return 0; }
  while read -r id; do
    [ -n "$id" ] && "$AERO" move-node-to-workspace --window-id "$id" "$ws" --focus-follows-window
  done <<< "$got"
  sleep 0.2
}

# ── tidy <workspace...> ───────────────────────────────────────────────
tidy() {
  local ws
  for ws in "$@"; do
    "$AERO" flatten-workspace-tree --workspace "$ws" 2>/dev/null
    "$AERO" layout --workspace "$ws" --root h_tiles 2>/dev/null
    "$AERO" balance-sizes --workspace "$ws" 2>/dev/null
  done
}

# ── stack_last_two <workspace> <bundle-id-oben> <bundle-id-unten> ─────
# Macht aus den letzten zwei Spalten eine vertikal geteilte Spalte.
# join-with erzeugt einen gemeinsamen Elterncontainer; weil
# enable-normalization-opposite-orientation-for-nested-containers = true
# gesetzt ist, wird dieser Container automatisch vertikal.
stack_last_two() {
  local ws="$1" top="$2" bottom="$3" top_id="" bot_id=""
  top_id="$(ids "$top" | head -1)"
  bot_id="$(ids "$bottom" | head -1)"
  # BEIDE müssen da sein. Fehlt der obere (z. B. Raindrop läuft nicht),
  # würde join-with den falschen linken Nachbarn erwischen und
  # stattdessen Claude über Reader stapeln.
  if [ -z "$top_id" ] || [ -z "$bot_id" ]; then
    echo "info: ${top##*.} oder ${bottom##*.} läuft nicht — keine Teilung, bleibt bei Spalten" >&2
    "$AERO" balance-sizes --workspace "$ws" 2>/dev/null
    return 0
  fi
  "$AERO" join-with --window-id "$bot_id" left 2>/dev/null \
    || echo "warn: join-with fehlgeschlagen — mit alt-shift-minus nachbauen" >&2
  "$AERO" balance-sizes --workspace "$ws" 2>/dev/null
}

# ── show <unten-ws> <oben-ws> ─────────────────────────────────────────
show() { "$AERO" workspace "$2"; "$AERO" workspace "$1"; }

# ── layout_report <workspace...> ──────────────────────────────────────
# Zeigt, was tatsächlich entstanden ist. Reihenfolge und Verschachtelung
# sind nicht zu 100 % erzwingbar — hiermit siehst du das Ergebnis.
layout_report() {
  local ws
  for ws in "$@"; do
    echo "── Workspace $ws ─────────────────────────────"
    "$AERO" list-windows --workspace "$ws" \
      --format '   %{window-layout}  %{app-name}  ·  %{window-title}' 2>/dev/null
  done
}
