#!/usr/bin/env bash
# @group: Aufbauen
# @label: Discover exakt (2)
# @key: alt-ctrl-2
set -euo pipefail
exec python3 "$(dirname "$0")/layout.py" discover
