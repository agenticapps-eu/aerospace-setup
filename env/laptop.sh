#!/usr/bin/env bash
# @group: Aufbauen
# @label: Profil an angeschlossene Monitore anpassen
# @key: alt-ctrl-m
set -euo pipefail
exec python3 "$(dirname "$0")/layout.py" monitor
