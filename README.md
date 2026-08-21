# aerospace-setup

Meine Konfiguration für [AeroSpace](https://github.com/nikitabobko/AeroSpace)
auf zwei **übereinander gestapelten** Ultrawide-Monitoren, plus die Skripte,
die ganze Arbeitsumgebungen in einem Rutsch aufbauen.

> **English:** A working AeroSpace configuration for two vertically stacked
> ultrawide monitors, with shell scripts that build entire workspace
> environments in one go. Comments and docs are in German.

## Das Layout

```
LG ULTRAWIDE  3440×1440   (oben)          1 DEV            Ghostty (herdr) │ Obsidian
──────────────────────────────────────────────────────────────────────────────────────
Odyssey G93SC 5120×1440   (unten, Main)   2 DISCOVER       Zen │ Claude │ Raindrop ⁄ Reader
                                          3 WORK           Dia │ Slack │ Google Meet
                                          4 COMMUNICATION  WhatsApp │ Fastmail
                                          5 REMOTE         Ghostty: VPS │ NAS
                                          6 TOOLS          Ghostty Terminal │ Chrome
                                          7 PRODUCTIVITY   ForkLift │ Superlist
```

**Warum der obere Monitor nur einen Workspace hat** — das ist die eine
Erkenntnis, die dieses Repo vielleicht auch für andere interessant macht:

AeroSpace parkt die Fenster unsichtbarer Workspaces in einer unteren Ecke
*ihres eigenen* Monitors. Bei nebeneinanderstehenden Monitoren fällt das nie
auf. Bei gestapelten Monitoren liegt unter dem oberen aber echter Bildschirm
— die geparkten Fenster wurden dort sichtbar, gemessen als 896 px breiter
Streifen quer über den unteren Monitor.

Ein Fensterverwalter kann das nicht sauber lösen, solange er irgendwo parken
muss. Die strukturelle Antwort ist, dem oberen Monitor **genau einen**
Workspace zu geben: dann ist dort nie etwas versteckt, und das Problem
existiert nicht mehr. Der untere Monitor hat es ohnehin nie, weil unter ihm
nichts liegt.

`macos/check-bleed.sh` misst das nach, falls jemand dasselbe Setup hat.

## Tastenbelegung

Zwei Ebenen, damit man nicht nachdenken muss, was gerade gemeint ist:

| | |
|---|---|
| `ctrl` + ←/→ | Workspace wechseln |
| `ctrl` + ↑/↓ | Monitor wechseln |
| `ctrl-shift` + Pfeil | dasselbe, Fenster mitnehmen |
| `alt` + Pfeil | Fenster **innerhalb** des Workspace fokussieren |
| `alt-shift` + Pfeil | Fenster im Raster umsortieren |
| `alt` + 1…7 | Workspace direkt |
| `alt-shift-f` | Fenster aus dem Raster lösen / zurück |
| `alt-b` | Raster gleichmässig verteilen |
| `alt-shift-minus` / `-equal` | Spalte vertikal teilen / zusammenfassen |
| `alt-ctrl-a` | alles aufbauen |

Die `ctrl`+Pfeil-Ebene übernimmt bewusst die Bedeutung, die Mission Control
vorher hatte — das Muskelgedächtnis bleibt erhalten. Dafür müssen die
System-Kürzel weichen:

```bash
macos/mission-control-keys.sh status   # was ist aktiv
macos/mission-control-keys.sh off      # abschalten, legt vorher ein Backup an
macos/mission-control-keys.sh restore  # Backup zurückspielen
```

Mission Control selbst bleibt über `F3` und Drei-Finger-Wisch erreichbar.

**Kleingedrucktes:** `alt`+←/→ ist auf macOS die wortweise Navigation im
Text. AeroSpace greift global, das verliert man also in Editoren. Wen das
stört: in `aerospace.toml` `alt-` durch `alt-ctrl-` ersetzen.

## Installieren

```bash
git clone https://github.com/agenticapps-eu/aerospace-setup.git
cd aerospace-setup
cp env/hosts.conf.example env/hosts.conf   # SSH-Ziele eintragen
./install.sh
./install.sh status                        # was liegt wo
```

`install.sh` legt Symlinks nach `~/.config/aerospace/` und
`~/.config/ghostty/config`, sichert vorhandene Dateien vorher weg und schiebt
ein eventuelles `~/.aerospace.toml` beiseite — AeroSpace meldet einen Fehler,
wenn die Config an zwei Orten liegt.

Voraussetzung: AeroSpace **0.21+**. Ältere Fassungen kennen
`auto-reload-config`, `focus-follows-mouse` und die `test`-Syntax in
`on-window-detected` nicht.

## Die Skripte

| | |
|---|---|
| `env/layout.conf` | **Soll-Tabelle:** Bundle-ID → Workspace |
| `env/build-all.sh` | ganze Umgebung aufbauen, `alt-ctrl-a` |
| `env/relayout.sh` | Fenster wieder einsortieren, `alt-ctrl-r` |
| `env/discover-layout.sh` | Workspace 2 exakt aufbauen, `alt-ctrl-2` |
| `env/ghostty-herdr.sh` · `-remote.sh` · `-tools.sh` | je ein Ghostty-Fenster |
| `env/gt.sh <profil>` | einzelnes Ghostty-Fenster für einen Zweck |
| `macos/check-bleed.sh` | misst überstehende Fenster (nur lesend) |
| `macos/monitor-arrangement.sh status` | Monitor-Origins anzeigen |

Die Kopfzeilen `# @label:` / `# @group:` / `# @key:` machen ein Skript in
[AeroPilot](https://github.com/agenticapps-eu/aeropilot) sichtbar, der
Menüleisten-App zu diesem Setup.

**Eine Soll-Tabelle, nicht drei.** `env/layout.conf` hält fest, welche App
auf welchen Workspace gehört. `relayout.sh` liest sie, AeroPilot liest sie,
und `alt-ctrl-r` stellt den Soll-Zustand her.

Der Grund ist eine Eigenschaft von AeroSpace, die leicht zu übersehen ist:
`on-window-detected` greift **nur, wenn ein Fenster erscheint** — nie
rückwirkend. Ändert man eine Regel oder nummeriert Workspaces um, bleibt
jedes bereits offene Fenster liegen, wo es war. Hier lagen deshalb nach
einer Umnummerierung sieben Fenster einen Tag lang auf ihren alten Nummern,
während die Config längst stimmte. Von aussen sah es aus, als sei eine App
weggerutscht — dabei war die neu geöffnete die einzige, die richtig lag.

**Ghostty ohne Tabs.** `ghostty/config` bindet alle 23 Tab-Kürzel ab. Native
macOS-Tabs sind mehrere Fenster in einer Gruppe — für einen Tiling-Manager
sind sie deshalb kein Detail, sondern unvereinbar: ein Klick auf einen
anderen Tab lässt scheinbar neue Fenster erscheinen. Ein Fenster pro Zweck
löst das.

## Was hier nicht drin ist

- **`env/hosts.conf`** — die SSH-Ziele. Vorlage: `hosts.conf.example`.
  Trag dort Aliase aus `~/.ssh/config` ein statt IPs; dann gibt es eine
  Stelle zum Nachziehen, wenn sich eine Adresse ändert.
- Die App selbst: [agenticapps-eu/aeropilot](https://github.com/agenticapps-eu/aeropilot).

## Lizenz

MIT
