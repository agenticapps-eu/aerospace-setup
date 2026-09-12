#!/usr/bin/env bash
# @group: Ghostty
# @label: hermes + homelab öffnen
# @key:   alt-ctrl-5
# ══════════════════════════════════════════════════════════════════════
# GHOSTTY · die zwei Remote-herdr-Sessions → Workspace 5
#                                            Hotkey: alt-ctrl-5
#   hermes   = VPS
#   homelab  = NAS (ugreen)
#
# Zwei EINZELNE Fenster, von AeroSpace zu Hälften gekachelt.
# Keine Tabs — warum, steht in gt.sh.
# ══════════════════════════════════════════════════════════════════════
source "$(dirname "$0")/_lib.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
rmdir "$LOCKDIR" 2>/dev/null; trap - EXIT

for p in hermes homelab; do
  "$HERE/gt.sh" "$p"
  sleep 0.6
done
"$AERO" balance-sizes --workspace 5 2>/dev/null
notify "hermes + homelab öffnen — aktives Monitorprofil"
