#!/usr/bin/env bash
# @group: Terminals
# @label: Ghostty herdr lokal → 1
# @key:   alt-ctrl-1
# ══════════════════════════════════════════════════════════════════════
# GHOSTTY · herdr lokal → Workspace 1        Hotkey: alt-ctrl-1
#
# Ein Fenster, ein Zweck, keine Tabs. Warum keine Tabs: siehe gt.sh.
# ══════════════════════════════════════════════════════════════════════
HERE="$(cd "$(dirname "$0")" && pwd)"
exec "$HERE/gt.sh" herdr
