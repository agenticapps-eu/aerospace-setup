# Betriebshandbuch

Stand: 20. August 2026 · AeroSpace 0.21.3-Beta · macOS 26.6 (Tahoe), arm64
LG ULTRAWIDE 3440×1440 (oben) · Odyssey G93SC 5120×1440 (unten, Main)

Das README erklärt, **was** das Setup ist. Diese Datei erklärt, **wie man
damit arbeitet** — und was zu tun ist, wenn etwas nicht stimmt.

---

## Der tägliche Ablauf

| | |
|---|---|
| `alt-ctrl-a` | morgens einmal: Apps öffnen, Ghostty aufsetzen, alles einordnen |
| `alt-ctrl-r` | zwischendurch: nur einordnen, öffnet und beendet nichts |
| `alt-ctrl-2` | Workspace 2 exakt wiederherstellen (Zen │ Claude │ Raindrop ⁄ Reader) |

Der erste Lauf dauert 30–60 Sekunden, weil Electron-Apps langsam starten.
Danach reicht `alt-ctrl-r`.

Dasselbe gibt es klickbar in **AeroPilot** (Menüleiste, Bereich *Aktionen*).
Die Liste dort ist nicht einprogrammiert: jedes Skript in `env/` meldet sich
über Kopfzeilen selbst an.

```bash
# @group: Aufbauen
# @label: Alles aufbauen
# @key:   alt-ctrl-a
```

---

## Tastenbelegung

**Zwei Ebenen.** Die Trennung ist der ganze Trick: `ctrl` bewegt dich
zwischen Workspaces und Monitoren, `alt` bewegt dich innerhalb eines
Workspace. Man muss nie überlegen, was gerade gemeint ist.

| | |
|---|---|
| `ctrl` + ←/→ | Workspace wechseln (nur auf dem aktuellen Monitor) |
| `ctrl` + ↑/↓ | Monitor wechseln — ↑ = LG, ↓ = Odyssey |
| `ctrl-shift` + Pfeil | dasselbe, Fenster mitnehmen |
| `alt` + Pfeil | Fenster innerhalb des Workspace fokussieren |
| `alt-shift` + Pfeil | Fenster im Raster umsortieren |
| `alt` + 1…7 | Workspace direkt |
| `alt-shift` + 1…7 | Fenster dorthin schieben (Fokus geht mit) |
| `alt-tab` | zurück zum vorherigen Workspace |
| `alt-shift-f` | Fenster aus dem Raster lösen ⁄ zurück |
| `alt-f` | Vollbild |
| `alt-b` | Raster gleichmässig verteilen |
| `alt-shift--` ⁄ `alt-shift-=` | Spalte vertikal teilen ⁄ zusammenfassen |
| `alt--` ⁄ `alt-=` | Grösse ±100 px |
| `alt-/` ⁄ `alt-,` | Ausrichtung kippen ⁄ Accordion — **Vorsicht, siehe unten** |
| `alt-shift-;` | Service-Modus (`esc` zurück, `r` = Baum plattmachen) |

Dazu die Skripttasten: `alt-ctrl-a` Aufbau, `alt-ctrl-r` Einordnen,
`alt-ctrl-2` Workspace 2, `alt-ctrl-1` ⁄ `-5` ⁄ `-6` die drei
Ghostty-Fenster.

`ctrl` + Pfeil hat bewusst die Bedeutung, die Mission Control vorher hatte —
das Muskelgedächtnis bleibt. Dafür mussten die Systemkürzel weichen:

```bash
macos/mission-control-keys.sh status    # was ist aktiv
macos/mission-control-keys.sh off       # abschalten, legt vorher ein Backup an
macos/mission-control-keys.sh restore   # Backup zurückspielen
```

Mission Control selbst bleibt über `F3` und Drei-Finger-Wisch erreichbar.

**Was das kostet:** `alt` + ←/→ ist auf macOS die wortweise Navigation im
Text, `alt-shift` + ←/→ die wortweise Auswahl. AeroSpace greift global, das
verliert man also in Obsidian, iA Writer und CotEditor. Wenn das stört: in
`aerospace.toml` `alt-` durch `alt-ctrl-` ersetzen.

---

## Die Bausteine

| Datei | wofür |
|---|---|
| `aerospace.toml` | Regeln, Tasten, Lücken, Monitorzuordnung |
| `env/layout.conf` | **Soll-Tabelle:** welche App auf welchen Workspace |
| `env/build-all.sh` | öffnet die markierten Apps, ruft dann relayout |
| `env/relayout.sh` | ordnet alle offenen Fenster nach der Soll-Tabelle |
| `env/discover-layout.sh` | baut Workspace 2 exakt auf |
| `env/gt.sh` | ein Ghostty-Fenster für einen Zweck |
| `env/hosts.conf` | SSH-Ziele (nicht im Repo) |
| `macos/*.sh` | Mission-Control-Kürzel, Monitor-Diagnose |
| AeroPilot | Menüleisten-App: Fenster, Config, Skripte, Warnungen |
| AutoRaise | Fokus folgt der Maus mit Verzögerung |

**Warum eine eigene Soll-Tabelle?** Weil `on-window-detected` in der
`aerospace.toml` nur greift, wenn ein Fenster **erscheint** — nie
rückwirkend. Die Tabelle ist die Fassung, die man jederzeit erneut anwenden
kann. Format:

```
<bundle-id>   <workspace>   [<titel-regex>]
```

Erste Übereinstimmung gewinnt, wie bei `on-window-detected` — deshalb stehen
Regeln mit Titelmuster **vor** der allgemeinen Regel derselben App.
Workspace `-` heisst „nie zuordnen". Ein `+` vor der Bundle-ID heisst
„beim Aufbau öffnen".

Die Bundle-ID einer App bekommst du in AeroPilot: im Bereich *App* die
Anzeige der Bundle-IDs einschalten, dann steht sie unter jedem Fenster und
lässt sich markieren.

---

## Wenn etwas nicht stimmt

### Ein Fenster ist auf jedem Workspace sichtbar

AeroSpace hat es aus der Verwaltung verloren. Es blendet fremde Workspaces
aus, indem es deren Fenster wegschiebt — was es nicht kennt, schiebt es nie
weg. Der Nachbar in derselben Spalte zieht sich derweil auf die volle Höhe,
weil er allein im Container steht.

**Prüfen:** `aerospace list-windows --monitor all | grep -i <app>` — oder
einfacher: AeroPilot zeigt es als orange Warnung.

**Beheben:** die App neu starten. Es gibt kein Kommando, das die
Fenstererfassung neu anstösst; nur ein neu erscheinendes Fenster wird
erfasst. In AeroPilot ist dafür ein Knopf. Danach `alt-ctrl-r`.

### Ein Workspace steht plötzlich hochkant

Bänder übereinander statt Spalten nebeneinander: die Wurzel des Workspace
ist auf vertikal gekippt. Auslösen kann das `alt-/`
(`layout tiles horizontal vertical`) mit einem einzigen Anschlag, wenn das
fokussierte Fenster direkt in der Wurzel liegt.

**Beheben:** `alt-ctrl-2` für Workspace 2, sonst
`aerospace layout --workspace N --root h_tiles` gefolgt von `alt-b`.

### Ein Fenster liegt auf dem falschen Workspace

Fast immer ein Fenster, das schon offen war, als sich eine Regel geändert
hat. AeroPilot meldet es blau; `alt-ctrl-r` räumt es ein.

### Ghostty macht auf einmal neue Fenster auf

Dann ist irgendwo ein Tab entstanden. Native macOS-Tabs sind mehrere Fenster
in einer Gruppe und mit Tiling unvereinbar. `ghostty/config` bindet alle 23
Tab-Kürzel ab, aber der Menüpunkt *Shell → New Tab* lässt sich nicht
entfernen.

**Beheben:** alle Ghostty-Fenster schliessen, dann `alt-ctrl-a` — oder
einzeln mit `gt.sh herdr` ⁄ `hermes` ⁄ `homelab` ⁄ `term` ⁄ `btop` ⁄ `spf`.

### AeroSpace reagiert gar nicht mehr

```bash
aerospace enable off     # Verwaltung aus, alle Fenster wieder frei
aerospace enable on      # zurück
```

Beides auch in AeroPilot unter *Aktionen*. Danach `alt-ctrl-a`.

---

## Fallen, die Zeit gekostet haben

**`--dry-run` gibt auch bei Fehlern Exit-Code 0 zurück.** Man muss die
Ausgabe lesen, nicht den Rückgabewert. AeroPilot macht genau das und rollt
bei `[ERROR]` automatisch zurück.

**`on-window-detected` ist nie rückwirkend.** Regel geändert oder Workspaces
umnummeriert? Jedes offene Fenster bleibt liegen. Deshalb gibt es
`layout.conf` und `alt-ctrl-r`.

**Tastenpositionen sind immer QWERTY.** AeroSpace liest physische
Tastenpositionen; Presets gibt es nur für Dvorak und Colemak. EurKEY hat
eine US-Basis, dort stimmt alles — auf der deutschen Belegung wandern
`alt-slash`, `alt-minus`, `alt-equal` und `alt-shift-semicolon` auf andere
Tasten. Die Tabelle dazu steht im Keybindings-Block der `aerospace.toml`.

**`--all` ist ein Alias für `--monitor all`** und kollidiert mit
Filter-Flags wie `--app-bundle-id`. In Kombination liefert es still eine
leere Liste.

**macOS bringt bash 3.2 mit.** Kein `mapfile`, kein `declare -A`. Deshalb
parallele Arrays in `_lib.sh`.

**Fenstertitel ändern sich im Betrieb.** Google Meet heisst in der Lobby
„Google Meet" und im Anruf „Meet – <Terminname> …". Titelregeln also mit
Anker, nicht mit exakter Gleichheit.

**TCC schützt Documents, Downloads und den Schreibtisch.** Eine ad-hoc
signierte App fragt dort nach **jedem** Rebuild erneut nach Erlaubnis, weil
sich der Signatur-Hash ändert. Deshalb liegt die Konfiguration unter
`~/Sourcecode`.

---

## Prüfwerkzeuge

```bash
aerospace list-windows --monitor all --format '%{workspace} %{app-name} %{window-title}'
aerospace list-workspaces --monitor all --format '%{workspace} %{monitor-name}'
aerospace reload-config --dry-run       # Ausgabe lesen, nicht den Exit-Code
macos/check-bleed.sh                    # überstehende Fenster messen (nur lesend)
macos/monitor-arrangement.sh status     # Monitor-Origins
```
