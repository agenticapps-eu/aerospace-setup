#!/bin/zsh -l
# ══════════════════════════════════════════════════════════════════════
# Wird von Ghostty als `command` gestartet. Setzt den Fenstertitel und
# startet dann das eigentliche Programm.
#
# WARUM DIESER UMWEG: Ghostty's `surface configuration` hat keine
# Titel-Eigenschaft, und TUI-Programme wie herdr, btop und superfile
# setzen den Titel nicht selbst. Ohne Titel heissen alle Fenster
# "Oh hello, Ghostty" und sind nicht zu unterscheiden. Ausserdem erspart
# die Datei Anführungszeichen im AppleScript: Ghostty bekommt nur einen
# Pfad plus einfache Wörter.
#
#   gt-run.sh <titel> [--retry] [befehl ...]
#
# --retry: bei Abbruch mehrmals neu verbinden, danach eine Shell öffnen
#          statt das Fenster sterben zu lassen. Für Remote-Sitzungen.
# ══════════════════════════════════════════════════════════════════════
title="$1"; shift
printf '\033]0;%s\007' "$title"

retry=0
if [ "${1:-}" = "--retry" ]; then retry=1; shift; fi

if [ "$#" -eq 0 ]; then
  exec /bin/zsh -l
fi

if [ "$retry" -eq 0 ]; then
  exec "$@"
fi

# ── Mit Wiederverbinden ───────────────────────────────────────────────
# Am 19. und 21.08.2026 sind die Sitzungen zu hermes und ugreen nachts
# um 02:15 und 03:29 sauber beendet worden — Netz weg oder Gegenstelle
# weg. Weil `exec` das Skript ersetzt hatte, endete damit auch der
# Ghostty-Befehl und das Fenster schloss sich. Die Fehlermeldung war
# nicht mehr zu sehen, und die Sitzung musste von Hand neu aufgebaut
# werden.
#
# Jetzt: ansteigende Wartezeit, höchstens fünf Versuche — ein kurzer
# Netzhänger heilt von selbst, eine echte Störung läuft nicht endlos
# im Kreis. Danach bleibt eine Shell offen, damit man sieht, was los
# war, und von Hand weitermachen kann.
n=0
while true; do
  "$@" && break
  code=$?
  n=$((n + 1))
  if [ "$n" -ge 5 ]; then
    printf '\n\033[31m✖ %s — nach %d Versuchen aufgegeben (Exit %d).\033[0m\n' \
           "$title" "$n" "$code"
    break
  fi
  wait_s=$((n * 5))
  printf '\n\033[33m⟳ %s — Verbindung weg (Exit %d). Versuch %d von 5 in %d s …\033[0m\n' \
         "$title" "$code" "$n" "$wait_s"
  sleep "$wait_s"
done

printf '\n\033[2mShell bleibt offen. Erneut verbinden: ↑ oder gt.sh %s\033[0m\n' "$title"
exec /bin/zsh -l
