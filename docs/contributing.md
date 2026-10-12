# Contributing

Read [README](../README.md) and [file placement](project_structure.md) before adding files. Read the relevant issue on the [OUUT Jira board](https://untoldtales.atlassian.net/jira/software/projects/OUUT/boards/2) before implementing a tracked task. The Fall 2026 demo covers the intro and Big Red's route.

## Branches and review

Create tracked-work branches from the Jira issue's **Development → Create branch → Create branch in GitHub** flow, using `main` as the base. Use `feature/`, `fix/`, `art/`, `audio/`, or `writing/` with the uppercase issue key, for example `feature/OUUT-1-title-game-screen`. The remote branch-created event triggers the automation that moves the story to **In Progress**; creating only a local branch does not trigger it. Fetch and check out the Jira-created branch before implementing. Never commit directly to `main`; keep it runnable. Check remote updates before starting and preserve local changes before pulling.

Submit a pull request and obtain a coder's review before merging. Include the OUUT issue key, the resulting behavior, checks performed, and remaining limitations. Review the diff before pushing. Run the [shared project check and visible F5/F6 check](setup.md#verify-the-project) before requesting review. Headless startup alone does not establish visual rendering, browser export, or macOS compatibility.

## Scene ownership

Coordinate ownership in Discord before editing an existing shared `.tscn`. One person edits each shared scene at a time. Keep reusable scenes small enough that unrelated tasks can edit different files. Move and rename resources through Godot, keeping resource identity and import metadata with them.

## Assets and plugins

Editable art/audio originals belong in shared team storage outside this repository. Ask the team for the current location. Commit only exported game-ready files under `assets/`; `.gitattributes` sends the configured binary formats through Git LFS. Keep SVG and scene/resource/script/dialogue text in regular Git. Add LFS patterns when introducing a new binary format rather than treating all files as binaries.

Use identifiable export names with a clear link to their original source in the asset handoff. Include credits and license notes for third-party assets. Art specifications remain with the art directors; folder creation does not decide sprite sizes or filtering.

Pin third-party plugins when they are introduced. Keep their files unchanged unless a documented patch is necessary, and record the version and patch. Dialogic is planned for a later integration ticket.

## Files to commit

Commit project-facing documentation, scripts, text scenes/resources, `.uid` sidecars, and asset `.import` settings. Exclude `.godot/`, `builds/`, local engine overrides, logs, and environment secrets. Never hardcode secrets.

Skills, Codex settings, agent instruction files, and generated agent plans stay local and ignored. Stage explicit project paths and inspect the staged file list before committing; do not commit these local tooling files or editable source art.
