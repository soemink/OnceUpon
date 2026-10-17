# Once Upon: Untold Tales

> *The woods are just trees, the trees are just wood.*

A 2.5D isometric dating sim built by the **CSUF Video Game Development Club (Fall 2026)**.

Bored of living the same day over and over, you leave your town walls for the first time, follow an eerie dirt path to a strange apothecary shop, and find a storybook that pulls you inside. Within its pages live the characters of the Grimm Brothers' tales and old nursery stories — each with a side of their story that was never told. Build relationships, uncover their untold tales, and find out what is rotting away the final pages of the book.

---

## Table of Contents

- [Game Overview](#game-overview)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Git Workflow](#git-workflow)
- [Project Tracking](#project-tracking)
- [Conventions](#conventions)
- [Asset Guidelines](#asset-guidelines)
- [Roadmap](#roadmap)
- [Team](#team)

---

## Game Overview

| | |
|---|---|
| **Genre** | Dating sim with exploration and minigames |
| **Perspective** | 2.5D isometric — 2D sprite characters in a 3D world, with 2D portraits during dialogue |
| **Length** | ~1 hour (subject to change) |
| **Platforms** | PC (Windows/Mac), web build on itch.io |
| **Inspirations** | Dream Daddy, Coral Island, Slay the Princess, Doki Doki Literature Club, Into the Woods |

### Love Interests

| Character | Tale | Key Side Characters |
|---|---|---|
| **Mateo Salvador** (Big Red) | Little Red Riding Hood | William Blackwood (Big Bad Wolf), Grandma |
| **Itzel Tacuani** (The Wolf) | The Three Little Pigs | Ezra, Finley & Caspian Lockehart |
| **Little Mermaid** | The Little Mermaid | Her father, the prince, her sisters, the sea witch |
| **Rapunzel** | Rapunzel | Gothel, the thief |
| **The Witch** *(secret)* | — | — |

### Core Systems

- **Isometric exploration** — walk through scenes, interact with characters and objects
- **Branching dialogue** — choices affect relationships and story flags
- **Relationship meters** — friendship meters that become a love meter for the character you choose
- **Story routes & endings** — good and bad endings per love interest
- **Minigames** — small optional challenges within each tale
- **Enter/leave the book** — move between the real world and the storybook

---

## Tech Stack

| Tool | Purpose |
|---|---|
| [Godot 4.7.2 standard](https://godotengine.org/) | Game engine; Compatibility renderer for desktop and web |
| GDScript | Programming language |
| [Dialogic 2](https://github.com/dialogic-godot/dialogic) | Planned dialogue integration; not installed in the foundation |
| [Blender](https://www.blender.org/) | 3D environment blockouts |
| GitHub + Git LFS | Version control |

> Everyone must use **Godot 4.7.2 standard**, as pinned in `.godot-version`. Use GDScript and the Compatibility renderer throughout this project.

---

## Getting Started

### 1. Install the tools

- [Godot 4.7.2](https://github.com/godotengine/godot/releases/tag/4.7.2-stable) — **standard version** (not .NET)
- [Git](https://git-scm.com/downloads)
- [Git LFS](https://git-lfs.com/) — required for art and audio files
- Optional: [GitHub Desktop](https://desktop.github.com/) if you prefer not to use the command line

### 2. Clone the repository

```bash
git clone https://github.com/soemink/OnceUpon.git
cd OnceUpon
git lfs install --local
git lfs pull
```

### 3. Open in Godot

1. Launch Godot 4.7.2 standard
2. Click **Import** and select the `project.godot` file in the repo
3. Wait for the first import to finish (it may take a few minutes)
4. Press **F5** to run the game

The project launches the illustrated title screen with Start Game, Settings, and Quit. Start Game shows an intro-coming-soon notice until the intro is integrated. Settings controls master volume. See [setup and checks](docs/setup.md), [file placement](docs/project_structure.md), and [contribution workflow](docs/contributing.md) before starting a feature. Blender is optional for contributors who create models.

To try the walking/running prototype, open `scenes/worlds/movement_test/movement_test.tscn` and press **F6**. Use WASD/arrows to walk, hold Shift to run, L to lock/unlock movement, and R to reset. See [movement controls and tuning](docs/movement_prototype.md).

---

## Project Structure

```
OnceUpon/
├── project.godot         # Root project; import this file
├── .godot-version        # Exact engine pin: 4.7.2
├── .github/workflows/    # Automated import and startup check
├── addons/               # Plugins (Dialogic, etc.)
├── assets/
│   ├── art/
│   │   ├── characters/   # Sprites, sorted by character
│   │   ├── portraits/    # Dialogue portraits & expressions
│   │   ├── environments/ # Textures, tiles, props
│   │   ├── ui/           # Menus, dialogue box, meters
│   │   └── cg/           # Story illustrations & endings
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── models/           # Blender blockouts (.glb exports)
│   └── fonts/
├── dialogue/             # Add route folders with real dialogue content
├── scenes/
│   ├── app/main.tscn     # Application entry; instances the title screen
│   ├── worlds/           # Hometown, apothecary, forest, etc.
│   ├── characters/
│   ├── ui/
│   └── minigames/
├── systems/              # Reusable logic shared across scenes
├── autoload/             # Persistent services, added only when needed
├── data/                 # Shared authored definitions and resources
├── tests/smoke/          # Main-scene startup check
├── tools/                # Shared local/CI check command
└── docs/                 # Setup, placement, and contribution guides
```

Keep a scene's scripts and private resources beside its `.tscn`. Shared exported assets stay in `assets/`. Empty reserved folders contain `.gitkeep`; create character, location, route, and system subfolders when their first content arrives. See the [ownership rules](docs/project_structure.md) for examples.

---

## Git Workflow

1. **Never commit directly to `main`.** `main` should always run.
2. Create your branch from the Jira story: **Development → Create branch → Create branch in GitHub**. Choose this repository, branch from `main`, and include the uppercase issue key, for example `feature/OUUT-1-title-game-screen`. This creates the remote branch and triggers the automation that moves the story to **In Progress**. Then fetch and check out that branch locally:
   ```bash
   git fetch origin
   git switch --track origin/feature/OUUT-1-title-game-screen
   ```
   Branch prefixes: `feature/`, `fix/`, `art/`, `audio/`, `writing/`
3. Commit often with clear messages:
   ```
   Add Mateo first-meeting dialogue
   Fix player walking behind cabin
   ```
4. Push and open a **Pull Request**. At least one coder reviews before merging.
5. **Pull before you start working** every session to avoid conflicts.

### Avoiding conflicts

- **Only one person edits a scene (`.tscn`) at a time.** Call it in Discord before you open a shared scene.
- Never commit the `.godot/` folder — it's in `.gitignore`.
- Exported binary assets under `assets/` use the Git LFS formats listed in `.gitattributes`. Editable source art and audio projects stay in shared team storage outside this repository.
- Commit `.uid` and asset `.import` metadata. Keep skills, Codex settings, agent instructions, and generated agent planning documents local and ignored.
- Run the [shared project check and manual F5 check](docs/setup.md#verify-the-project) before requesting review.

---

## Project Tracking

Use the [Once Upon Untold Tales Jira board](https://untoldtales.atlassian.net/jira/software/projects/OUUT/boards/2) to track project tasks, bugs, and progress. The Jira project key is `OUUT`, and the board ID is `2`.

This README is the guide for the game's scope, setup, structure, and conventions. Use Jira for task-specific requirements and current work status. Reference the relevant issue key (for example, [OUUT-4](https://untoldtales.atlassian.net/browse/OUUT-4)) in branches and pull requests when working on a tracked task.

---

## Conventions

### Code (GDScript)

- Follow the [official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- `snake_case` for files, variables and functions
- `PascalCase` for class names and nodes
- `CONSTANT_CASE` for constants
- Typed functions and variables; tabs for GDScript indentation
- Comment anything that isn't obvious

### File naming

- All lowercase, underscores, no spaces: `mateo_portrait_happy.png`
- Prefix by type when helpful: `bg_`, `ui_`, `sfx_`, `mus_`

### Story flags & variables

Keep all relationship values and story flags in Dialogic variables or the `GameState` autoload, never scattered across scripts.

```
relationship.mateo        # 0–100
flags.met_william         # true/false
flags.chosen_partner      # "mateo", "itzel", ...
```

---

## Asset Guidelines

> Final specs are set by the Art Directors (Kai & Christina). Ask before deviating.

| Asset | Spec |
|---|---|
| Character sprites | TBD px tall, 4 walk directions |
| Portraits | TBD px, transparent PNG; expressions: neutral, happy, flustered, angry, sad |
| Textures | Power-of-two sizes (512, 1024, 2048) |
| Music | `.ogg`, loopable |
| SFX | `.wav` or `.ogg` |
| 3D models | Export from Blender as `.glb` |

Keep working files (`.psd`, `.blend`, `.kra`, and audio projects) in shared team storage **outside this repository**. Ask the team for the current location. Only exported, game-ready files go in `assets/`; retain a clear naming link to their originals and include third-party credits/licenses where needed.

---

## Roadmap

**Goal:** playable demo by end of Fall 2026 semester — intro + Big Red's route.

- [ ] Lock engine version, art specs and demo scope
- [ ] Player movement, camera and collision prototype
- [ ] Dialogic set up with placeholder portraits
- [ ] Relationship meter & story flags
- [ ] Hometown / dirt path / apothecary intro
- [ ] Forest & cabin environment
- [ ] Mateo, William & Grandma sprites and portraits
- [ ] Big Red route dialogue implemented
- [ ] UI pass (menus, dialogue box, meters)
- [ ] Music & SFX integrated
- [ ] Save / load
- [ ] Playtest & web demo build

**Later:** Itzel, Little Mermaid and Rapunzel routes, the Witch's secret route, minigames, full release.

---

## Team

| Role | Members |
|---|---|
| Project Manager | Bianka |
| Art Directors | Kai, Christina |
| Environment Artists | Ithzcally, Morgan, Eunkyo,  Marcel |
| Character Design | Kai, Ahn, Morgan |
| UI & Graphic Design | Lauren, Maddy |
| Music | Sebastian |
| Programming | Anthony, Kenneth, MK |
| Social Media | Jac |

**We're recruiting!** Coders, animators, musicians/SFX, environment artists, writers and 3D generalists — beginners welcome. Reach out on Discord.

### Contact

Discord is our main channel. Reach out to Bianka, Christina, or Kai there for any questions.

---

*Made with love by the CSUF VGDC · Fall 2026*
