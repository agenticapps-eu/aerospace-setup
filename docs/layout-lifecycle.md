# Monitorprofile und sichere Wiederherstellung

Mit LG/Odyssey oder einem anderen externen Monitor bleibt das Desktop-Profil aktiv.
Erst nur mit eingebautem Bildschirm gilt: 1 herdr, 2 hermes, 3 homelab,
4 Zen, 5 Claude, 6 Obsidian, 7 übrige Fenster floatend.

AeroPilot gleicht das Profil beim Start und nach ruhenden Monitorereignissen ab.
„Fenster zuordnen“ verschiebt nach denselben Regeln wie neue Fenster, ohne
Layoutbäume global zurückzusetzen. „Discover“ richtet explizit Desktop-WS2:
Zen links, Claude, Codex, weitere Kacheln, Raindrop/Reader zusammen rechts.
Vorhandene floatende Fenster bleiben floatend. Temporäre Laptop-Floats werden
beim Rückwechsel wiederhergestellt; manuelle dauerhafte Float-Regeln haben Vorrang.

Falls Fenster laut AeroSpace richtig zugeordnet, aber unsichtbar sind, zusätzlich
native macOS-Schreibtische prüfen. Diese Skripte löschen keine Spaces. F3 ist
hier durch Dropzone belegt; Mission Control über die App öffnen.

Die Regeln stehen in env/layout.conf und env/layout.laptop.conf. Der Status liegt
unter ~/.local/state/aerospace/profile.json, Fehler in layout.log. Zum Anhalten:
`touch ~/.local/state/aerospace/disabled`. Zum Fortsetzen Datei entfernen und
`~/.config/aerospace/env/monitorwechsel.sh` aufrufen. Einen beschädigten Status erst
sichern und prüfen; nicht blind löschen, da er temporäre Float-Zustände enthält.

Tests: `python3 -m unittest discover -s tests -v`. Die Simulation prüft beide
Profile, neue Fenster, Rückkehr, Fehlerfälle und Discover-Reihenfolge. Sie ersetzt
keinen physischen Ab-/Anstecktest. build-all startet Apps, beendet aber keine
laufenden Ghostty-Sitzungen; wiederholter expliziter Aufbau kann zusätzliche
Terminalfenster öffnen.
