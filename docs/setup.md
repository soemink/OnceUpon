# Setup

Use **Godot 4.7.2 standard** (GDScript, not .NET), Git, and Git LFS. The exact engine pin is in `.godot-version`. Use Compatibility rendering throughout the project. Blender is optional for model authoring.

The game uses a **1920 × 1080 (16:9)** base resolution with `canvas_items` scaling. The title screen preserves its proportions when the window is resized.

## Clone and open

```bash
git clone https://github.com/soemink/OnceUpon.git
cd OnceUpon
git lfs install --local
git lfs pull
```

Launch Godot 4.7.2 standard, click **Import**, and select the repository's root `project.godot`. Wait for import to finish. Press **F5** to run the project: the illustrated title screen should show Start Game, Settings, and Quit.

## Verify the project

Use PowerShell 7 (`pwsh`) for the shared check. From the repository root, supply the path to your standard Godot executable:

```powershell
pwsh -File ./tools/check_project.ps1 -GodotPath 'E:\GoDot Game Engine\Godot_v4.7.2-stable_win64_console.exe'
```

That path is the owner's Windows installation; other contributors use their own path. On Windows, use the console executable so diagnostics can be captured. If `godot` is on your PATH, run:

```powershell
pwsh -File ./tools/check_project.ps1
```

The check verifies the pinned engine, imports the project, checks startup, exercises title-screen input and settings, verifies desktop Quit in a separate process, and checks player movement, collisions, and camera follow. It must report `PROJECT_SMOKE_OK`, `TITLE_SCREEN_TEST_OK`, `TITLE_SCREEN_QUIT_REQUESTED`, `PLAYER_MOVEMENT_TEST_OK`, and `Project import and startup passed.` Audio preference tests use an isolated file and restore the audio bus afterward. Engine errors, a wrong engine version, missing success output, or a timeout fail the check. The same script runs on GitHub pull requests and pushes to `main`.

For diagnostic runs without PowerShell, these engine commands work on Windows, Linux, and macOS:

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/smoke/project_smoke.gd
godot --headless --path . --script res://tests/ui/title_screen_test.gd
godot --headless --path . --script res://tests/ui/title_screen_test.gd -- --quit-check
godot --headless --path . --script res://tests/movement/player_movement_test.gd
```

Inspect their output for errors and require `PROJECT_SMOKE_OK`; the PowerShell wrapper is the authoritative automated check because it checks diagnostics and timeouts as well as exit codes.

Also perform the visible editor check:

1. Open `scenes/app/main.tscn` and confirm **Compatibility** is selected.
2. Press **F5**, then stop and press **F6** with that scene open.
3. Resize the running game window; the artwork should retain its proportions and all buttons should remain visible.
4. Hover each button, then use arrows/Tab and Enter. The gold selection ornaments should follow focus. Start Game should show the temporary intro notice; dismiss it with Back or Escape.
5. Open Settings, adjust master volume, and return with Back or Escape. Reopen the game and verify the volume is retained. Confirm keyboard focus stays inside Settings while it is open.
6. Confirm the debugger reports no errors, then verify Quit closes the desktop game. Quit is hidden in web builds, where the browser owns the tab.

The automated check verifies import, startup, title-screen behavior, and the movement prototype. For movement playtesting, open `scenes/worlds/movement_test/movement_test.tscn` and press **F6**. See [movement controls, tuning, and checks](movement_prototype.md). Visible rendering, web exports, and macOS execution need their own checks. Export templates and presets will be added with export work.

## Troubleshooting and next steps

Read the first reported engine error. Confirm Godot 4.7.2 standard, run `git lfs pull`, and reimport before investigating references or script errors. Generated `.godot/` content stays local; `.uid` and asset `.import` settings stay in Git.

Dialogic 2 is planned but is not installed in this foundation. OUUT-2 supplies a standalone walking/running and camera test room; integration with the story, story state, saving, final art specifications, and exports remain separate work. Read [file placement](project_structure.md) and [contribution workflow](contributing.md) before adding content.
