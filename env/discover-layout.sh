#!/usr/bin/env bash
# @group: Aufbauen
# @label: Discover exakt (2)
# ══════════════════════════════════════════════════════════════════════
# Workspace 2 · DISCOVER exakt aufbauen
#
#   ┌──────────┬──────────┬──────────┐
#   │          │          │ Raindrop │
#   │   Zen    │  Claude  ├──────────┤
#   │          │          │  Reader  │
#   └──────────┴──────────┴──────────┘
#     ein Drittel  ein Drittel  ein Drittel, vertikal geteilt
#
# WARUM DAS VORHER SCHIEFGING:
# `join-with left` fasst das fokussierte Fenster mit dem NÄCHSTEN Nachbarn
# links zusammen. Ich hatte blind angenommen, die Fenster stünden in
# Aufrufreihenfolge — dadurch war der linke Nachbar von Reader mal Claude
# statt Raindrop, und Claude landete gestapelt.
#
# Jetzt: Reihenfolge erst AUSLESEN, dann sortieren, dann zusammenfassen.
# Gelesen wird über `focus --dfs-index`, das die Fenster in Baumreihenfolge
# durchgeht — AeroSpace hat keine Interpolationsvariable für die Position.
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"

WS=2
ZEN=app.zen-browser.zen
CLAUDE=com.anthropic.claudefordesktop
RAINDROP=io.raindrop.macapp
READER=io.readwise.read

# ── 1) Alle vier in den Workspace, Baum plattmachen ───────────────────
for b in "$ZEN" "$CLAUDE" "$RAINDROP" "$READER"; do
  while read -r id; do
    [ -n "$id" ] && "$AERO" move-node-to-workspace --window-id "$id" "$WS"
  done <<< "$(ids "$b")"
done
"$AERO" workspace "$WS"
sleep 0.4
"$AERO" flatten-workspace-tree --workspace "$WS" 2>/dev/null
"$AERO" layout --workspace "$WS" --root h_tiles 2>/dev/null
sleep 0.3

# ── 2) Ziel-Reihenfolge bestimmen ─────────────────────────────────────
target=()
for b in "$ZEN" "$CLAUDE" "$RAINDROP" "$READER"; do
  id="$(ids "$b" | head -1)"
  [ -n "$id" ] && target+=("$id")
done
n=${#target[@]}
if [ "$n" -lt 2 ]; then
  echo "Zu wenige Fenster auf $WS ($n) — nichts zu ordnen." ; exit 0
fi
echo "Ziel-Reihenfolge (links → rechts): ${target[*]}"

# ── read_order: aktuelle Baumreihenfolge über dfs-index ───────────────
read_order() {
  local i out=()
  local cnt; cnt="$("$AERO" list-windows --workspace "$WS" --count 2>/dev/null)"
  for i in $(seq 0 $((cnt-1))); do
    "$AERO" focus --dfs-index "$i" 2>/dev/null || continue
    out+=("$("$AERO" list-windows --focused --format '%{window-id}' 2>/dev/null)")
  done
  printf '%s\n' "${out[@]}"
}

# ── read_into_cur: mapfile gibt es in macOS' bash 3.2 nicht ───────────
read_into_cur() {
  cur=()
  while IFS= read -r line; do
    [ -n "$line" ] && cur+=("$line")
  done < <(read_order)
}

# ── 3) Sortieren: jedes Zielfenster an seine Position schieben ────────
# Selection Sort mit `move left` — jeder Schritt tauscht mit dem Nachbarn,
# also maximal n² Schritte. Bei vier Fenstern ist das nichts.
for pass in 1 2 3 4; do
  read_into_cur
  ok=1
  for i in "${!target[@]}"; do
    [ "${cur[$i]:-}" != "${target[$i]}" ] && { ok=0; break; }
  done
  [ "$ok" = 1 ] && break

  # erste falsche Position finden
  for i in "${!target[@]}"; do
    want="${target[$i]}"
    [ "${cur[$i]:-}" = "$want" ] && continue
    # wo steckt `want` gerade?
    pos=-1
    for j in "${!cur[@]}"; do [ "${cur[$j]}" = "$want" ] && { pos=$j; break; }; done
    [ "$pos" -lt 0 ] && break
    while [ "$pos" -gt "$i" ]; do
      "$AERO" move --window-id "$want" left 2>/dev/null
      pos=$((pos-1))
      sleep 0.15
    done
    break
  done
done

read_into_cur
echo "Ist-Reihenfolge:              ${cur[*]}"

# ── 4) Reader unter Raindrop: jetzt IST der linke Nachbar Raindrop ────
reader_id="$(ids "$READER" | head -1)"
rain_id="$(ids "$RAINDROP" | head -1)"
if [ -n "$reader_id" ] && [ -n "$rain_id" ]; then
  "$AERO" focus --window-id "$reader_id" 2>/dev/null
  sleep 0.2
  "$AERO" join-with --window-id "$reader_id" left 2>/dev/null \
    && echo "Reader mit Raindrop zusammengefasst" \
    || echo "warn: join-with fehlgeschlagen"
else
  echo "info: Raindrop oder Reader fehlt — keine Teilung"
fi

sleep 0.3
"$AERO" balance-sizes --workspace "$WS" 2>/dev/null

echo
echo "── Ergebnis Workspace $WS ──"
"$AERO" list-windows --workspace "$WS" \
  --format '   %{window-layout}  %{app-name}' 2>/dev/null
