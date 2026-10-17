# Walking and running prototype — OUUT-2

Open `scenes/worlds/movement_test/movement_test.tscn` in Godot 4.7.2 standard and press **F6** to run this scene. F5 still opens the title screen. The test room is development content, not the story's intro.

| Input | Behavior |
| --- | --- |
| WASD or arrow keys | Walk relative to the screen |
| Hold Shift while moving | Run |
| Release directions | Stop immediately |
| L | Simulate a dialogue/menu movement lock; press again to resume |
| R | Reset player and camera, and unlock movement |

Move around the long wall, the L-shaped obstacle, and the room's perimeter. Walk speed starts at 3 m/s; run speed starts at 4.5 m/s. Starts, stops, and switching speed have no horizontal acceleration. Diagonal movement has the same ground speed as cardinal movement. The character has four facing directions and keeps the last facing when stopped. Walking into a wall stops the walk animation when the body stops moving.

The camera follows at a fixed isometric angle and orthographic zoom. Follow smoothing is independent of movement responsiveness. Physics interpolation smooths rendering between physics ticks. Lose application focus to verify player movement stops; held controls can resume on focus return.

## Reuse and tune

Instance `scenes/characters/player/player.tscn` in a world with floor collision. Assign its **Movement Camera** to the world's Camera3D so controls follow the camera's ground-plane axes. Without a camera reference, movement uses world X/Z axes. Set **Walk Speed** and **Run Speed** on the player instance. World collision is layer 1; the player is layer 2 and scans layer 1. The root body owns velocity, facing, and locomotion; it does not own the camera.

The current follow script belongs to the test room. Its exported **Target** and **Follow Speed** let the composing scene change its target or smoothing. Keep the rig outside the player hierarchy. Call `snap_to_target()` after teleporting and reset the player's physics interpolation, as the room's reset control does. If multiple locations later share this camera, promote it to a shared camera scene then.

Dialogue, menus, or cutscenes should call the player's `set_movement_enabled(false)` before taking control and `set_movement_enabled(true)` when returning control. Locking clears horizontal velocity immediately while gravity and floor contact continue. `is_movement_enabled()` reports this scene-level lock; focus loss is a separate input gate and does not remove a dialogue lock. The composing world must coordinate overlapping locks; do not unlock until all its blocking UI/cutscenes have ended. Pausing the SceneTree also pauses the player.

## Placeholder art

The original geometric sheet at `assets/art/characters/player/player_placeholder.svg` is temporary prototype art, not an approved character design. Its 96 × 96 cells use facing rows down, up, left, right; each row has four poses. `player_frames.tres` defines `idle_<direction>`, `walk_<direction>`, and `run_<direction>`; idle uses one pose, walk uses 8 fps, and temporary running reuses those poses at 12 fps. Replace the SpriteFrames resource with team-approved art that preserves these animation names. Art directors set final dimensions, frame counts, and running animation requirements.

## Verification

Run the shared check from `docs/setup.md`. It now includes the movement suite and requires `PLAYER_MOVEMENT_TEST_OK`. The suite exercises movement through real physics ticks, direction mappings, tunable speeds, lock/unlock, facing, floor/wall collision, sliding, corner escape, and camera following. It runs alongside existing title-screen and startup checks.

Also perform these visible checks:

1. Press F6 on the room and confirm the sprite, instructions, obstacles, and grid render correctly.
2. Walk and run in every direction. Release keys and Shift separately; check immediate response and constant diagonal speed.
3. Run into walls and corners, slide along them, and turn away.
4. Press L while moving; keep holding movement keys and confirm the player stays put. Press L again and confirm movement resumes.
5. Press R after moving away; confirm player and camera reset without drifting from the old position.
6. Switch application focus away and back. Confirm the player stops while unfocused.
7. Watch the camera while walking, running, and stopping; check for visible jitter. Resize the window and confirm controls remain legible.

Web execution requires a matching Godot web export template, a development export preset, and a browser run. A passing desktop/headless suite alone does not verify the web build. Export configuration remains separate from this movement prototype; exclude tests and the development room from a future story-only release unless deliberately included.
