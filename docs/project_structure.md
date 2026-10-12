# Project structure

Import `project.godot` at the repository root. This is one Godot project. Scene modules keep their scenes, scripts, and private resources together; exported assets and dialogue have central homes.

```text
OnceUpon/
  project.godot
  .godot-version
  .gitignore
  .gitattributes
  .editorconfig
  .github/workflows/project-check.yml
  addons/
  assets/
    art/{characters,portraits,environments,ui,cg}/
    audio/{music,sfx}/
    models/
    fonts/
  dialogue/
  scenes/
    app/main.tscn
    worlds/
    characters/
    ui/
    minigames/
  systems/
  autoload/
  data/
  tests/smoke/project_smoke.gd
  tools/check_project.ps1
  docs/{setup,project_structure,contributing}.md
```

Braces above list sibling directories or files. Empty reserved folders contain `.gitkeep` so Git retains them. Add character, location, route, and system subfolders when their first content arrives; remove their placeholder once the folder contains real files.

## Where files belong

| Home | Owns | Future example |
| --- | --- | --- |
| `scenes/app/` | Entry and composition of world and UI scenes | `main.tscn` |
| `scenes/worlds/<location>/` | A location's scene and local behavior | `forest/forest.tscn` and `forest.gd` |
| `scenes/characters/<type>/` | Character scenes and local behavior | `player/player.tscn` and `player.gd` |
| `scenes/ui/<component>/` | UI scenes and their scripts | `relationship_meter/relationship_meter.tscn` |
| `scenes/minigames/<game>/` | One self-contained minigame | Its scenes, scripts, and private resources |
| `systems/<system>/` | Logic reused by multiple scenes | Relationship calculations; no UI ownership |
| `autoload/` | Services that must survive scene changes | Session state or saving, when needed |
| `data/<domain>/` | Shared resource definitions and authored values | Character definitions and route metadata |
| `dialogue/<route>/` | Dialogue timelines and characters | `intro/`, `big_red/` after Dialogic integration |
| `assets/` | Exported, game-ready art, audio, models, fonts | Portraits grouped by character |
| `addons/` | Pinned third-party plugins | Dialogic in its integration ticket |
| `tests/` | Development checks and test scenes | Main-scene startup smoke check |
| `tools/` | Development automation | Common local/CI check command |
| `docs/` | Setup, workflow, and architecture guidance | These contributor guides |

Keep a scene's `.gd` scripts and private `.tres` resources beside its `.tscn`. Move logic into `systems/` only when it has actual consumers across scenes. Put shared content definitions in `data/`; mutable session/save state needs a separate, explicit owner. Avoid catch-all `misc/`, `helpers/`, and `managers/` folders.

`assets/` contains only exports. Editable PSD, Krita, Blender, and audio-project originals belong in shared team storage outside Git. Obtain its current location from the team; preserve a naming link between each original and export.

## Runtime ownership

For each mutable value, define its owner, who may change it, and which signal tells consumers it changed. Presentation requests changes through the owner's API. UI should not directly edit persistent game data.

Children emit typed signals upward; parents call explicit methods downward and mediate siblings. Use scene-unique names or exported references instead of depending on another scene's internal node paths. Add persistent autoloads or a global event bus only when actual lifetime or communication requirements justify them. Keep scene-local state local.

The application entry instances `scenes/ui/title_screen/title_screen.tscn`, which owns menu focus, the temporary Start notice, and desktop Quit. Its `start_requested` signal is the integration point for the future intro: connect a listener to replace the notice. The title screen instances `scenes/ui/settings/settings_panel.tscn`, which owns master-volume preferences and saves them in `user://settings.cfg`. These UI scenes run independently with F6 and require no autoload. Dialogic, movement, relationships, and game save/load remain future work.

## Naming and import boundaries

Use lowercase `snake_case` file/folder names, `PascalCase` node/class names, typed GDScript, and tabs in `.gd` files. Use LF line endings and commit resource `.uid` sidecars and asset `.import` settings. Move or rename resources through Godot to preserve references.

`docs/` and `tools/` have `.gdignore` files so Godot skips their development content. Local agent tooling is also excluded from imports and Git. `tests/` remains importable so the engine can run its smoke script; future export configuration must exclude test content. `.godot/` is generated locally and ignored by Git.
