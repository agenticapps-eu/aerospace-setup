#!/usr/bin/env bash
# @group: Workspace starten
# @label: Workspace 5 öffnen (aktives Profil)
# ══════════════════════════════════════════════════════════════════════
# Duenner Knopf fuer AeroPilot. Die Arbeit macht ws-open.sh, das die
# Apps aus layout.conf liest — hier steht bewusst KEINE eigene Liste.
# Fuer die Ghostty-Workspaces (1, 5, 6) ruft ws-open.sh die vorhandenen
# ghostty-*.sh auf; die Eintraege unter "Ghostty" bleiben daneben
# bestehen, sie sind der direkte Weg ohne Umweg ueber layout.conf.
# ══════════════════════════════════════════════════════════════════════
exec "$(dirname "$0")/ws-open.sh" 5
