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
#
# WAS SICH GEÄNDERT HAT (20.08.2026): Die Zuordnung App → Workspace stand
# hier fest im Skript, ein zweites Mal in relayout.sh und ein drittes Mal
# als on-window-detected in der aerospace.toml. Drei Listen, die bei jeder
# Änderung einzeln nachgezogen werden mussten — und beim Umnummerieren der
# Workspaces eben nicht wurden. Jetzt gibt es nur noch layout.conf:
#
#   dieses Skript   öffnet die mit `+` markierten Apps
#   relayout.sh     schiebt alles an seinen Platz
#
# Damit ist der Aufbau nichts anderes als „Apps öffnen, dann aufräumen".
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

# Der Lock aus _lib.sh würde die Unterskripte blockieren — hier freigeben
# und selbst verwalten.
rmdir "$LOCKDIR" 2>/dev/null; trap - EXIT

read_layout || exit 1

# ── 1) Ghostty ────────────────────────────────────────────────────────
# Zuerst komplett beenden: bestehende macOS-Tab-Gruppen lösen sich nicht
# nachträglich auf, AppleWindowTabbingMode gilt nur für NEUE Fenster.
echo "▸ Ghostty zurücksetzen …"
ghostty_reset

echo "▸ Ghostty: herdr lokal (1), Remote (5), Terminal (6) …"
"$HERE/ghostty-herdr.sh"
"$HERE/ghostty-remote.sh"
"$HERE/ghostty-tools.sh"

# ── 2) Apps öffnen ────────────────────────────────────────────────────
# Erst alle anstossen, dann gemeinsam warten. Nacheinander zu warten
# würde die Startzeiten addieren statt sie zu überlappen.
todo=()
for i in "${!r_bundle[@]}"; do
  [ "${r_auto[$i]}" = "ja" ] || continue
  b="${r_bundle[$i]}"
  case " ${todo[*]:-} " in *" $b "*) continue ;; esac
  todo+=("$b")
done
echo "▸ ${#todo[@]} Apps öffnen …"
for b in "${todo[@]}"; do
  open -b "$b" >/dev/null 2>&1 || echo "  warn: $b startet nicht"
done

echo "▸ auf Fenster warten …"
for i in $(seq 1 80); do        # max. 20 s
  missing=()
  for b in "${todo[@]}"; do
    [ -z "$(ids "$b")" ] && missing+=("$b")
  done
  [ ${#missing[@]} -eq 0 ] && break
  sleep 0.25
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "  ohne Fenster geblieben: ${missing[*]}"
  echo "  (kein Abbruch — der Rest wird trotzdem eingeordnet)"
fi

# ── 3) Einordnen ──────────────────────────────────────────────────────
# Ab hier macht relayout.sh die Arbeit: Soll-Tabelle lesen, verschieben,
# ausgleichen, Workspace 2 verschachteln.
echo "▸ einordnen …"
"$HERE/relayout.sh"

# Fokus: unten Discover, oben Dev
show 2 1
notify "Setup aufgebaut — 7 Workspaces"
