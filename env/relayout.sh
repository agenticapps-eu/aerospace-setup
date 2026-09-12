#!/usr/bin/env bash
# @group: Aufbauen
# @label: Fenster zuordnen — Layouts behalten
# @key: alt-ctrl-r
set -euo pipefail
exec python3 "$(dirname "$0")/layout.py" relayout
