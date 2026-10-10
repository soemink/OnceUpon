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
| [Godot 4](https://godotengine.org/) | Game engine |
| GDScript | Programming language |
| [Dialogic 2](https://github.com/dialogic-godot/dialogic) | Dialogue, portraits, choices, variables |
| [Blender](https://www.blender.org/) | 3D environment blockouts |
| GitHub + Git LFS | Version control |

> ⚠️ Everyone must use the **same Godot 4 version**. Check the pinned message in Discord for the exact version before opening the project.

---

## Getting Started

### 1. Install the tools

- [Godot 4](https://godotengine.org/download) — **standard version** (not .NET)
- [Git](https://git-scm.com/downloads)
- [Git LFS](https://git-lfs.com/) — required for art and audio files
- Optional: [GitHub Desktop](https://desktop.github.com/) if you prefer not to use the command line

### 2. Clone the repository

```bash
git lfs install
git clone <repository-url>
cd once-upon-untold-tales
git lfs pull
```

### 3. Open in Godot

1. Launch Godot 4
2. Click **Import** and select the `project.godot` file in the repo
3. Wait for the first import to finish (it may take a few minutes)
4. Press **F5** to run the game

---

## Project Structure

```
once-upon-untold-tales/
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
├── dialogue/             # Dialogic timelines & characters
│   ├── intro/
│   ├── big_red/
│   ├── wolf/
│   ├── mermaid/
│   ├── rapunzel/
│   └── witch/
├── scenes/
│   ├── worlds/           # Hometown, apothecary, forest, etc.
│   ├── characters/
│   ├── ui/
│   └── minigames/
├── scripts/
│   ├── autoload/         # Global singletons (GameState, SaveManager)
│   ├── player/
│   ├── npc/
│   └── systems/          # Relationships, flags, transitions
└── project.godot
```

---

## Git Workflow

1. **Never commit directly to `main`.** `main` should always run.
2. Create a branch for your work:
   ```bash
   git checkout -b feature/mateo-dialogue
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
- Large binary files (PSD, PNG, WAV, Blender files) are tracked by Git LFS automatically.

---

## Conventions

### Code (GDScript)

- Follow the [official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- `snake_case` for files, variables and functions
- `PascalCase` for class names and nodes
- `CONSTANT_CASE` for constants
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

Keep working files (`.psd`, `.blend`, `.kra`) in a separate `source/` folder or shared drive — only exported, game-ready files go in `assets/`.

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
| Environment Artists | Ithzcally, Morgan |
| Character Design | Morgan |
| UI & Graphic Design | Lauren, Maddy |
| Artists | Sebastian, Jac, Marcel |
| Music | Seb |
| Programming | Anthony, Kenneth |
| Social Media | Hachi |

**We're recruiting!** Coders, animators, musicians/SFX, environment artists, writers and 3D generalists — beginners welcome. Reach out on Discord.

### Contact

Discord is our main channel. Reach out to Bianka, Christina, or Kai there for any questions.

---

*Made with love by the CSUF VGDC · Fall 2026*