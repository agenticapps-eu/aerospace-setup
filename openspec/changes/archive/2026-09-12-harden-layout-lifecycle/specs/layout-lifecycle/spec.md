## ADDED Requirements

### Requirement: Hardware selects one routing policy
The controller SHALL select laptop routing only when all detected monitors are built-in; any external monitor selects desktop routing. Empty or failed detection SHALL leave state unchanged.

#### Scenario: A laptop reconnects to an external monitor
- **WHEN** A laptop reconnects to an external monitor
- **THEN** The controller restores desktop assignments and only floating layouts it temporarily introduced, retaining existing float choices.

### Requirement: New and existing windows agree
The controller SHALL route new windows and explicit relayout using the same active rules; desktop uses layout.conf and laptop uses layout.laptop.conf.

#### Scenario: A new Zen or utility window opens on the laptop
- **WHEN** A new Zen or utility window opens on the laptop
- **THEN** Zen goes to workspace 4 and the utility to floating workspace 7; desktop callbacks cannot leave it on workspace 2.

### Requirement: Monitor changes preserve layout trees
A same-profile monitor change SHALL reload config without flattening or reordering workspaces.

#### Scenario: LG disconnects while Odyssey stays connected
- **WHEN** LG disconnects while Odyssey stays connected
- **THEN** Desktop routing remains active and custom layout trees remain intact.

### Requirement: Discover accounts for every tiled window
Explicit Discover layout SHALL put Zen first, include Codex and all extra tiled windows, preserve floats, and only join Reader after verifying adjacency to Raindrop.

#### Scenario: Codex, two Zen windows and a floating helper are open
- **WHEN** Codex, two Zen windows and a floating helper are open
- **THEN** Both Zen windows appear first, extra tiles are accounted for, only the intended pair is grouped, and focus is restored.

### Requirement: Recover without closing sessions
Normal relayout SHALL move only misplaced windows without flattening unrelated trees or restarting apps.

#### Scenario: User requests recovery during terminal work
- **WHEN** User requests recovery during terminal work
- **THEN** Terminal processes remain running and non-target layout trees are unchanged.
