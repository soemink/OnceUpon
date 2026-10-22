# Movement and camera prototype — OUUT-2 / OUUT-6

Open `scenes/worlds/movement_test/movement_test.tscn` in Godot 4.7.2 standard and press **F6**. F5 still opens the title screen. The room is development content, not the story intro.

| Input | Behavior |
| --- | --- |
| WASD or arrow keys | Walk relative to the requested camera direction |
| Hold Shift while moving | Run at exactly twice walking speed |
| Release directions | Stop immediately |
| Q / E | Rotate view left / right by 45 degrees per press |
| Mouse wheel up / down | Zoom in / out within limits |
| L | Toggle the test movement lock |
| R | Reset player, unlock movement, and snap camera to the player |

Walking starts at 3 m/s and running at 6 m/s. Changing walking speed also changes running speed to preserve the 2x ratio. Starts, stops, and speed changes are immediate; diagonals have the same ground speed as cardinal directions. The placeholder sprite has four facing directions, retains its last facing when stopped, and stops its locomotion animation when blocked by a wall.

The elevated perspective camera follows smoothly without rotating when the character turns. Q/E sets a new heading in 45-degree steps; holding a key does not repeat the step. Rotation takes the shortest path across 360 degrees. Movement uses the requested heading immediately while the visible camera catches up, matching the reference behavior researched for OUUT-6. Wheel zoom transitions smoothly, with a steeper downward pitch when farther out. These defaults are inspired by Don't Starve Together and tuned to this prototype's scale.

## Illustrated forest art test

The same room now tests the mechanics inside a temporary illustrated forest. Upright camera-facing tree, rock, and fern cutouts sit over a textured ground plane and irregular ochre path. Unshaded artwork and soft ground shadows reduce the appearance of solid 3D blocks. The original floor, long wall, L-shaped corner, and perimeter collision shapes remain in their tested positions; continuous rows of illustrated stones mark those obstacle footprints. Additional tree trunks have narrow cylinder collisions. The grid and original block meshes are hidden.

Characters and scenery use alpha-blended whole-cutout sorting with origins at their feet. This gives coherent front/behind layering as the camera orbits, rather than letting tilted character and upright scenery planes slice through one another. Ordinary opaque-ground depth testing remains enabled. Dark rubble strips and overlapping stone-shadow chains are intentionally absent; only soft tree/player grounding shadows remain.

`forest_scenery.gd` owns only this room's decorative composition. It instances the generated tree and ground exports from `assets/art/environments/forest_style_test/` and original SVG rock/fern placeholders. This is a visual comparison prototype, not final approved environment art or a story location. The existing placeholder character remains unchanged. Final art direction and production assets still belong to the art team.

When replacing art, keep the trunk base grounded, preserve alpha, and test every 45-degree orbit and both zoom limits. Run `tests/visual/forest_style_test.gd` (included in the shared check) to verify the clearing supports movement, illustrated trunk collisions block passage, and lock/reset/camera integration continue to work.

The separate rendered `tests/visual/sprite_occlusion_test.gd` compares the opaque silhouette of a front cutout in isolation and with another cutout behind it. It checks both front/behind arrangements at all eight headings and the close/distant viewing pitches. Run without `--headless`; see the command in [setup](setup.md). This catches rendering regressions that headless movement tests cannot detect.

## Reference for future development

Retain this test room as a reference and regression sandbox for actual game development. It demonstrates the agreed movement, camera, collision, and illustrated-sprite behavior together; its layout is not an authored story location. Keep the room runnable as production scenes are added so changes can be compared against a known example.

For the intro and Big Red's route:

1. Create each actual location under `scenes/worlds/<location>/`. Instance the reusable player and camera scenes and assign their target/movement references as described below. Keep room-specific scenery generation, HUD, and L/R debug shortcuts in this test room.
2. Replace temporary character and environment artwork with team-approved exports. Preserve animation names or update their mappings, keep drawing/sorting origins at ground contact, and fit collision shapes to the new assets' walkable footprints.
3. Connect future dialogue, menus, and cutscenes through the movement/camera control interfaces. The composing story scene owns transitions and overlapping locks; dialogue progression, relationships, story flags, and saving require separate implementation.
4. Tune camera framing and movement against each real location, then verify collision, front/behind sprite layering during orbit/zoom, and control restoration after dialogue. Run the shared checks and rendered occlusion regression after related changes.

The temporary forest artwork demonstrates a possible 2D presentation and does not establish final art direction. Keep the test room and test content excluded from future story-only exports; export configuration and web/macOS validation remain separate work.

## Reuse and tune

Instance `scenes/characters/player/player.tscn` in a world with floor collision. Instance `scenes/camera/exploration_camera_rig.tscn` separately; set its **Target** to the player. On the player, assign **Movement Reference** to the rig and **Movement Camera** to its Camera3D. The rig's `get_movement_basis()` supplies the requested orientation. Without that provider the player uses the assigned Camera3D's ground-plane axes; without either reference it uses world X/Z axes.

The player owns locomotion, collision, facing, and its movement lock. Set **Walk Speed** on the player; `run_speed` is a derived value, not an independent Inspector setting. World collision is layer 1; the player is layer 2 and scans layer 1.

The camera rig owns view state and a separate camera-input lock. Its top-level transform ignores composing parent rotation and scale, so it stays upright and keeps distances in world units. Keep it outside the player hierarchy. Its Inspector settings are:

| Setting | Default | Purpose |
| --- | --- | --- |
| Target Offset | (0, 0.85, 0) | World-space framing above the target origin |
| Initial Heading Degrees | 45 | Starting orbit heading |
| Initial Distance | 22 | Starting camera distance |
| Min / Max Distance | 14 / 32 | Zoom limits in world units |
| Min / Max Pitch Degrees | 30 / 60 | Close / distant downward viewing angle |
| Field Of View | 35 | Perspective vertical field of view |
| Follow / Rotation / Zoom Speed | 12 / 14 / 8 | Independent exponential smoothing rates |
| Zoom Step | 2 | Distance change per wheel event |

The InputMap actions are `camera_rotate_left`, `camera_rotate_right`, `camera_zoom_in`, and `camera_zoom_out`. They default to Q/E and the mouse wheel and can be rebound through normal Godot InputMap configuration.

Use `set_heading(degrees, snap=false)` and `set_distance(distance, snap=false)` for programmatic view changes; distance is clamped to configured bounds. `get_target_heading()` returns degrees; `get_target_distance()` returns the requested distance. `snap_to_target()` snaps position and in-progress view transitions to their requested values. R retains the requested heading and zoom while removing old follow/rotation/zoom lag. After teleporting a physics target, call its `reset_physics_interpolation()` before snapping the rig.

Assigning a new **Target** changes who the camera follows; null or freed targets leave the anchor in place safely. Assign a new valid target and call `snap_to_target()` when an immediate handoff is required.

Dialogue, menus, and cutscenes call `player.set_movement_enabled(false)` and `rig.set_controls_enabled(false)` before taking control, then restore each when finished. The composing world must coordinate overlapping locks and restore only after all blockers end. The camera lock stops user orbit/zoom inputs while allowing follow and programmatic view changes. Focused GUI controls also suppress camera keys/wheel; UI-consumed mouse events never reach world camera input. Ctrl/Alt/Meta key shortcuts and key repeats do not orbit the camera. Losing application focus gates both player and camera input without clearing their explicit locks. Pausing the SceneTree pauses both scenes.

## Placeholder art

`assets/art/characters/player/player_placeholder.svg` is temporary geometric art, not an approved character design. Its 96 × 96 cells use facing rows down, up, left, right with four poses per row. `player_frames.tres` defines `idle_<direction>`, `walk_<direction>`, and `run_<direction>`; idle uses one pose, walk uses 8 fps, and temporary running reuses those poses at 12 fps. Replace it with team-approved art that preserves animation names. The billboard faces the camera throughout orbiting.

## Verification

Run the shared check from `docs/setup.md`. It requires both `PLAYER_MOVEMENT_TEST_OK` and `EXPLORATION_CAMERA_TEST_OK` alongside the existing startup/title checks. Tests exercise real physics ticks and injected keyboard/mouse events: movement ratios, collision/sliding, facing, locks/focus, orbit steps/echo/wrap, requested-heading movement during rotation, bounded zoom/pitch, smooth transitions, GUI suppression, reset, target handoff, and reuse under transformed parents.

Visible checks:

1. Run the room; verify the character, instructions, illustrated trees/stone obstacles, textured ground, and path render clearly. Stone rows mark the continuous collision boundary.
2. Walk/run in every direction; release movement and Shift separately and check immediate response.
3. Orbit with Q/E while walking and running; hold a rotation key and check it adds only one step. Orbit across the starting direction in both directions.
4. Zoom to both limits and reverse; check smooth transitions, readable framing, and increasing downward tilt farther out.
5. Run into walls/corners, slide along them, and turn away.
6. Press L while moving, keep holding movement, then unlock; check the sprite stops and resumes correctly.
7. Press R during movement and camera transitions; the player resets and the camera snaps without old-position drift, retaining requested angle/zoom.
8. Switch application focus away/back; movement stops while unfocused. Resize the window; controls remain legible. Watch walking/running/stopping for jitter.

Web execution needs matching export templates, presets, and a browser run. A desktop/headless pass does not establish web behavior. Export setup remains separate scope; future story-only exports should deliberately exclude tests and the development room.
