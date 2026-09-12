#!/usr/bin/env bash
# @group: Ghostty
# @label: Terminal öffnen
# @key:   alt-ctrl-6
# ══════════════════════════════════════════════════════════════════════
# GHOSTTY · einfaches Terminal → Workspace 6   Hotkey: alt-ctrl-6
#
# Auf 6 liegen Terminal und Chrome nebeneinander (Chrome kommt über die
# on-window-detected-Regel dorthin, sobald du es öffnest).
#
# btop und superfile sind NICHT mehr Teil des Standardaufbaus — bei
# Bedarf einzeln:  gt.sh btop   bzw.  gt.sh spf   (beide landen auf 6)
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
rmdir "$LOCKDIR" 2>/dev/null; trap - EXIT

"$HERE/gt.sh" term
"$AERO" balance-sizes --workspace 6 2>/dev/null
notify "Terminal öffnen — aktives Monitorprofil"
