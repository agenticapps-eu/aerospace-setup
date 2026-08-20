#!/bin/zsh -l
# ══════════════════════════════════════════════════════════════════════
# Wird von Ghostty als `command` gestartet. Setzt den Fenstertitel und
# ersetzt sich dann durch das eigentliche Programm.
#
# WARUM: Ghostty's `surface configuration` hat keine Titel-Eigenschaft,
# und TUI-Programme wie herdr, btop und superfile setzen den Titel nicht
# selbst. Ohne Titel heissen alle Fenster "Oh hello, Ghostty" — dann kann
# weder ich sie prüfen noch du sie unterscheiden.
#
# Der Umweg über diese Datei erspart Anführungszeichen im AppleScript:
# Ghostty bekommt nur einen Pfad plus einfache Wörter übergeben.
#
#   gt-run.sh <titel> [befehl ...]
# ══════════════════════════════════════════════════════════════════════
title="$1"; shift
printf '\033]0;%s\007' "$title"
if [ "$#" -eq 0 ]; then
  exec /bin/zsh -l
else
  exec "$@"
fi
