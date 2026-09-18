# iTerm2 — Profil „Ghostty-Look"

`dynamic-profile.json` gehoert nach

    ~/Library/Application Support/iTerm2/DynamicProfiles/aerospace.json

iTerm liest den Ordner im laufenden Betrieb; die Datei wirkt sofort, ohne
Neustart und ohne einen Klick in den Einstellungen.

## Was drinsteht

Alles aus Ghosttys effektiver Konfiguration uebernommen, nicht geraten:

| | |
|---|---|
| Farben | Catppuccin Mocha, Palette 1:1 aus `Ghostty.app/Contents/Resources/ghostty/themes/Catppuccin Mocha` |
| Schrift | FiraCode Nerd Font Mono 16 — PostScript-Name `FiraCodeNFM-Reg`, nicht der Anzeigename |
| Ligaturen | an (Ghostty rendert sie ebenfalls) |
| Transparenz | 0.15 — Ghosttys `background-opacity = 0.85` ist dasselbe von der anderen Seite gezaehlt |
| Blur | an, Radius 20 |
| Cursor | Block, blinkend |

## Standardprofil

    defaults write com.googlecode.iterm2 "Default Bookmark Guid" \
      -string "ghostty-look-aerospace"

Nur schreiben, wenn iTerm **nicht** laeuft — beim Beenden schreibt iTerm
seine Einstellungen aus dem Speicher zurueck und ueberbuegelt den Eintrag.

Dazu abgeschaltet, analog zu Ghosttys `window-save-state = never`:

    defaults write com.googlecode.iterm2 NSQuitAlwaysKeepsWindows -bool false
    defaults write com.googlecode.iterm2 OpenArrangementAtStartup -bool false
