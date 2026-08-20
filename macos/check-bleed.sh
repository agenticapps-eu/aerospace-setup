#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════
# Prüft, ob versteckte Fenster auf dem anderen Monitor durchblitzen.
#
#   ./check-bleed.sh
#
# Rein lesend: kein Workspace-Wechsel, kein Fokuswechsel, nichts wird
# verschoben. Gefahrlos während der Arbeit.
#
# Wie es funktioniert: AeroSpace parkt Fenster von unsichtbaren
# Workspaces in einer unteren Ecke ihres Monitors, fast vollständig aus
# dem Bild geschoben. Liegt dort echter Bildschirm (weil ein zweiter
# Monitor darunter steht), wird das geparkte Fenster dort sichtbar.
# Das Skript rechnet für jedes versteckte Fenster nach, ob es die Fläche
# eines FREMDEN Monitors überlappt — und wie viele Pixel.
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
AERO="$(command -v aerospace || echo /opt/homebrew/bin/aerospace)"

SCREENS=$(osascript -l JavaScript -e '
ObjC.import("AppKit");
var s = $.NSScreen.screens, main = $.NSScreen.mainScreen.frame, out = [];
for (var i = 0; i < s.count; i++) {
  var x = s.objectAtIndex(i), f = x.frame;
  // NSScreen: y waechst nach oben, Ursprung unten links des Hauptschirms.
  // System Events: y waechst nach unten, Ursprung oben links des Hauptschirms.
  var seTop = main.size.height - (f.origin.y + f.size.height);
  out.push([ObjC.unwrap(x.localizedName), f.origin.x, seTop, f.size.width, f.size.height].join("|"));
}
out.join("\n")')

VISIBLE=$("$AERO" list-workspaces --monitor all --visible 2>/dev/null | tr '\n' ' ')
WINDOWS=$("$AERO" list-windows --monitor all \
          --format '%{workspace}|%{monitor-name}|%{app-name}' 2>/dev/null)

POS=$(osascript <<'EOS' 2>/dev/null
set res to ""
tell application "System Events"
  repeat with p in (every application process whose background only is false)
    try
      repeat with w in windows of p
        set pt to position of w
        set sz to size of w
        set res to res & (name of p) & "|" & (item 1 of pt) & "|" & (item 2 of pt) & "|" & (item 1 of sz) & "|" & (item 2 of sz) & linefeed
      end repeat
    end try
  end repeat
end tell
res
EOS
)

SCREENS="$SCREENS" VISIBLE="$VISIBLE" WINDOWS="$WINDOWS" POS="$POS" python3 - <<'PY'
import os

screens = []
for line in os.environ["SCREENS"].strip().splitlines():
    n, x, y, w, h = line.split("|")
    screens.append({"n": n, "x": float(x), "y": float(y), "w": float(w), "h": float(h)})

visible = set(os.environ["VISIBLE"].split())
wins = {}
for line in os.environ["WINDOWS"].strip().splitlines():
    ws, mon, app = line.split("|", 2)
    wins.setdefault(app.strip(), []).append((ws.strip(), mon.strip()))

pos = {}
for line in os.environ["POS"].strip().splitlines():
    if line.count("|") != 4: continue
    app, x, y, w, h = line.split("|")
    pos.setdefault(app.strip(), []).append(tuple(float(v) for v in (x, y, w, h)))

print("Monitore (System-Events-Koordinaten, y nach unten):")
for s in screens:
    print(f"  {s['n']:16} x {s['x']:>7.0f} .. {s['x']+s['w']:>7.0f}   "
          f"y {s['y']:>6.0f} .. {s['y']+s['h']:>6.0f}")
print(f"\nSichtbare Workspaces: {' '.join(sorted(visible)) or '—'}\n")

def overlap(a, b):
    ax, ay, aw, ah = a
    ox = max(0, min(ax + aw, b["x"] + b["w"]) - max(ax, b["x"]))
    oy = max(0, min(ay + ah, b["y"] + b["h"]) - max(ay, b["y"]))
    return ox, oy

problems = 0
checked = 0
for app, entries in sorted(wins.items()):
    for ws, mon in entries:
        if ws in visible:
            continue
        rects = pos.get(app) or pos.get(app.replace("‎", "").strip())
        if not rects:
            print(f"  ?  {app:16} ws {ws:2}  (Position nicht lesbar — Bedienungshilfen?)")
            continue
        own = next((s for s in screens if s["n"] == mon), None)
        for r in rects:
            checked += 1
            for s in screens:
                if own and s["n"] == own["n"]:
                    continue
                ox, oy = overlap(r, s)
                if ox > 2 and oy > 2:
                    problems += 1
                    print(f"  ✗  {app:16} ws {ws:2} ({mon})  blitzt auf {s['n']} durch: "
                          f"{ox:.0f}×{oy:.0f} px")

print()
if checked == 0:
    print("Keine versteckten Fenster zum Prüfen — auf jedem Monitor ist alles sichtbar.")
elif problems == 0:
    print(f"✅ Sauber. {checked} versteckte Fenster geprüft, keins ragt auf einen fremden Monitor.")
else:
    print(f"❌ {problems} von {checked} versteckten Fenstern blitzen durch.")
PY
