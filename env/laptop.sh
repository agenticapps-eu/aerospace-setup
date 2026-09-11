#!/usr/bin/env bash
# @group: Aufbauen
# @label: Laptop — nur eingebauter Schirm
# @key:   alt-ctrl-m
# ══════════════════════════════════════════════════════════════════════
# LAPTOP-LAYOUT · unterwegs, ohne externe Monitore
#                                            Hotkey: alt-ctrl-m
#
#   1  Ghostty herdr (lokal)
#   2  Ghostty hermes   (VPS)
#   3  Ghostty homelab  (NAS)
#   4  Zen
#   5  Claude
#   6  Obsidian
#   7  alles andere, floating
#
# WARUM EINE APP PRO WORKSPACE statt gekachelt:
# Auf dem eingebauten Schirm ist Kacheln kein Gewinn mehr — zwei Fenster
# nebeneinander sind beide zu schmal zum Arbeiten. Umgeschaltet wird
# stattdessen mit alt-1..7, das ist auf einem Schirm schneller als jede
# Anordnung.
#
# ZURÜCK AN DEN SCHREIBTISCH: alt-ctrl-a (build-all.sh). Dieses Skript
# ist bewusst nur die eine Richtung — die andere gibt es schon.
#
# Die Ghostty-Fenster sind nur am TITEL zu unterscheiden, alle teilen
# com.mitchellh.ghostty. Titel setzt gt-run.sh; herdr überschreibt ihn
# beim Verbinden, weshalb gt-run.sh einmal verzögert nachfasst.
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"

move_id() {   # <window-id> <workspace>
  [ -n "$1" ] && "$AERO" move-node-to-workspace --window-id "$1" "$2" 2>/dev/null
}

# ── Ghostty nach Titel verteilen ──────────────────────────────────────
# Erste Übereinstimmung gewinnt; was auf nichts passt, faellt unten in 7.
platziert=""
for paar in "hermes:2" "homelab:3" "herdr:1"; do
  titel="${paar%%:*}"; ws="${paar##*:}"
  while read -r id; do
    [ -z "$id" ] && continue
    case " $platziert " in *" $id "*) continue ;; esac
    move_id "$id" "$ws"; platziert="$platziert $id"
    # EXAKTER Titelvergleich per awk, nicht ids_titled: die Funktion
    # stellt intern '\|.*' vor das Muster, ein verankertes '^herdr$'
    # landet damit mitten im Ausdruck und trifft nie. Die Titel sind
    # ohnehin exakt 'herdr', 'hermes', 'homelab' — gesetzt von gt-run.sh.
  done <<< "$("$AERO" list-windows --monitor all --app-bundle-id "$GHOSTTY_BID" \
              --format '%{window-id}|%{window-title}' 2>/dev/null \
              | awk -F'|' -v t="$titel" '$2==t{print $1}')"
done

# ── Die drei Einzelapps ───────────────────────────────────────────────
for paar in "app.zen-browser.zen:4" "com.anthropic.claudefordesktop:5" "md.obsidian:6"; do
  bid="${paar%%:*}"; ws="${paar##*:}"
  while read -r id; do
    [ -z "$id" ] && continue
    move_id "$id" "$ws"; platziert="$platziert $id"
  done <<< "$(ids "$bid")"
done

# ── Alles Uebrige nach 7, floatend ────────────────────────────────────
# Auch die restlichen Ghostty-Fenster (term, btop, spf) landen hier —
# sie sind unterwegs Beiwerk, nicht das, wofuer man den Laptop aufklappt.
while read -r zeile; do
  id="${zeile%%|*}"
  [ -z "$id" ] && continue
  case " $platziert " in *" $id "*) continue ;; esac
  move_id "$id" 7
  "$AERO" layout floating --window-id "$id" 2>/dev/null
done <<< "$("$AERO" list-windows --monitor all --format '%{window-id}|%{app-name}' 2>/dev/null)"

# ── Aufraeumen ────────────────────────────────────────────────────────
for ws in 1 2 3 4 5 6; do
  "$AERO" flatten-workspace-tree --workspace "$ws" 2>/dev/null
  "$AERO" balance-sizes --workspace "$ws" 2>/dev/null
done

"$AERO" workspace 1 2>/dev/null
notify "Laptop-Layout — 1 herdr · 2 hermes · 3 homelab · 4 Zen · 5 Claude · 6 Obsidian · 7 Rest"
