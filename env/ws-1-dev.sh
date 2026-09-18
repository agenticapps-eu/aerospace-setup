#!/usr/bin/env bash
# @group: Workspace starten
# @label: 1 · DEV öffnen
# ══════════════════════════════════════════════════════════════════════
# Duenner Knopf fuer AeroPilot. Die Arbeit macht ws-open.sh, das die
# Apps aus layout.conf liest — hier steht bewusst KEINE eigene Liste.
# Die Terminals (Ghostty auf 1, iTerm auf 1, cmux auf 5) ruft ws-open.sh
# ueber ihre eigenen Skripte auf; die Eintraege unter "Terminals"
# bleiben daneben bestehen, sie sind der direkte Weg.
# ══════════════════════════════════════════════════════════════════════
exec "$(dirname "$0")/ws-open.sh" 1
