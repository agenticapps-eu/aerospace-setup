#!/usr/bin/env bash
# @group: Aufbauen
# @label: Monitorwechsel verarbeiten
# @key: alt-ctrl-w
set -euo pipefail
exec python3 "$(dirname "$0")/layout.py" monitor
