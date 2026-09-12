#!/usr/bin/env bash
# @group: Workspace starten
# @label: Workspace 3 öffnen (aktives Profil)
# ══════════════════════════════════════════════════════════════════════
# Duenner Knopf fuer AeroPilot. Die Arbeit macht ws-open.sh, das die
# Apps aus layout.conf liest — hier steht bewusst KEINE eigene Liste,
# sonst gaebe es eine vierte Stelle, an der die Zuordnung auseinander-
# laufen kann.
# ══════════════════════════════════════════════════════════════════════
exec "$(dirname "$0")/ws-open.sh" 3
