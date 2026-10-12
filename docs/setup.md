# Setup

Use **Godot 4.7.2 standard** (GDScript, not .NET), Git, and Git LFS. The exact engine pin is in `.godot-version`. Use Compatibility rendering throughout the project. Blender is optional for model authoring.

## Clone and open

```bash
git clone https://github.com/soemink/OnceUpon.git
cd OnceUpon
git lfs install --local
git lfs pull
```

Launch Godot 4.7.2 standard, click **Import**, and select the repository's root `project.godot`. Wait for import to finish. Press **F5** to run the project: the title `Once Upon: Untold Tales` should appear in the center of the window.

## Verify the project

Use PowerShell 7 (`pwsh`) for the shared check. From the repository root, supply the path to your standard Godot executable:

```powershell
pwsh -File ./tools/check_project.ps1 -GodotPath 'E:\GoDot Game Engine\Godot_v4.7.2-stable_win64_console.exe'
```

That path is the owner's Windows installation; other contributors use their own path. On Windows, use the console executable so diagnostics can be captured. If `godot` is on your PATH, run:

```powershell
pwsh -File ./tools/check_project.ps1
```

The check verifies the pinned engine, imports the project, loads the configured main scene, and processes startup frames. It must finish with `PROJECT_SMOKE_OK` and `Project import and startup passed.` Engine errors, a wrong engine version, missing success output, or a timeout fail the check. The same script runs on GitHub pull requests and pushes to `main`.

For diagnostic runs without PowerShell, these engine commands work on Windows, Linux, and macOS:

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/smoke/project_smoke.gd
```

Inspect their output for errors and require `PROJECT_SMOKE_OK`; the PowerShell wrapper is the authoritative automated check because it checks diagnostics and timeouts as well as exit codes.

Also perform the visible editor check:

1. Open `scenes/app/main.tscn` and confirm **Compatibility** is selected.
2. Press **F5**, then stop and press **F6** with that scene open.
3. Resize the running game window; the title should remain centered and visible.
4. Confirm the debugger reports no errors.

The automated check verifies import and startup. Visible rendering, web exports, and macOS execution need their own checks. Export templates and presets will be added with export work.

## Troubleshooting and next steps

Read the first reported engine error. Confirm Godot 4.7.2 standard, run `git lfs pull`, and reimport before investigating references or script errors. Generated `.godot/` content stays local; `.uid` and asset `.import` settings stay in Git.

Dialogic 2 is planned but is not installed in this foundation. Gameplay, camera, story state, saving, art import specifications, and exports belong to later tickets. Read [file placement](project_structure.md) and [contribution workflow](contributing.md) before adding content.
