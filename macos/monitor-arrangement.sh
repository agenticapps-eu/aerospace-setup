#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════
# Monitor-Anordnung für AeroSpace
#
#   ./monitor-arrangement.sh status    aktuelle Origins + Bewertung
#   ./monitor-arrangement.sh fix       linke Kanten fluchten lassen
#   ./monitor-arrangement.sh revert    Stand vom 17.08.2026 zurück
#
# WARUM: AeroSpace parkt versteckte Fenster in einer unteren Ecke des
# jeweiligen Monitors. Lag der LG mittig über dem Odyssey, war der Bereich
# unter beiden LG-Ecken echter Bildschirm — die geparkten Fenster wurden
# auf dem Odyssey sichtbar. Fluchten die linken Kanten, liegt der Bereich
# links-unterhalb des LG im Nichts und die Fenster verschwinden dort.
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
LG=A677CD8D-6906-4487-B09D-7208473465F0
OD=FAAEA563-4D6D-4FE4-8A83-0F645E24FDF8

# ── STILLGELEGT am 17.08.2026 ─────────────────────────────────────────
# Seit der LG nur einen Workspace hat, ist dort nie ein Fenster versteckt
# und das Durchblitzen kann gar nicht auftreten. Die Monitor-Anordnung
# muss nicht mehr angefasst werden.
#
# Ausserdem ist der Odyssey inzwischen Hauptbildschirm — die unten
# einprogrammierten Origins stammen von VORHER und würden deine
# Anordnung kaputtmachen. Deshalb sind fix und revert gesperrt.
# `status` bleibt nutzbar.
if [ "${1:-status}" = "fix" ] || [ "${1:-status}" = "revert" ]; then
  echo "GESPERRT: '$1' würde veraltete Koordinaten setzen (Stand vor dem"
  echo "Wechsel des Hauptbildschirms) und deine Anordnung verschieben."
  echo "Wird nicht mehr gebraucht: der LG hat nur einen Workspace."
  echo "Anordnung nur noch von Hand in Systemeinstellungen → Displays."
  exit 1
fi

case "${1:-status}" in
  fix)
    displayplacer \
      "id:$LG res:3440x1440 hz:60  color_depth:8 enabled:true scaling:off origin:(0,0)    degree:0" \
      "id:$OD res:5120x1440 hz:240 color_depth:8 enabled:true scaling:off origin:(0,1440) degree:0"
    ;;
  revert)
    displayplacer \
      "id:$LG res:3440x1440 hz:60  color_depth:8 enabled:true scaling:off origin:(0,0)       degree:0" \
      "id:$OD res:5120x1440 hz:240 color_depth:8 enabled:true scaling:off origin:(-785,1440) degree:0"
    ;;
  status)
    osascript -l JavaScript -e '
    ObjC.import("AppKit");
    var s=$.NSScreen.screens,a=[];
    for(var i=0;i<s.count;i++){var x=s.objectAtIndex(i),f=x.frame;
      a.push({n:ObjC.unwrap(x.localizedName),x:f.origin.x,y:f.origin.y,w:f.size.width});}
    var lg=a.filter(function(v){return /lg/i.test(v.n)})[0];
    var od=a.filter(function(v){return /odyssey/i.test(v.n)})[0];
    var r=["LG      x "+lg.x+" .. "+(lg.x+lg.w),"Odyssey x "+od.x+" .. "+(od.x+od.w),""];
    var ok = lg.x <= od.x || (lg.x+lg.w) >= (od.x+od.w);
    r.push(ok ? "OK - der LG hat eine freie untere Ecke, versteckte Fenster bleiben unsichtbar."
              : "PROBLEM - beide unteren LG-Ecken liegen ueber dem Odyssey. ./monitor-arrangement.sh fix");
    r.join("\n")'
    ;;
  *) echo "status | fix | revert"; exit 1 ;;
esac
