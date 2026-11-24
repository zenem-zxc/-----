# Repository Guidelines

## Project Structure

This is a Godot 4.7 project (`project.godot`, project name `notkyora`) configured for mobile rendering. Keep game content in the project root or organize it into clear folders as it is added (for example, `scenes/`, `scripts/`, `assets/`, and `tests/`). The existing `addons/godot_mcp/` directory contains the Godot MCP plugin; treat it as third-party code and avoid unrelated edits. `.godot/` is generated editor/import state and is excluded from version control. Keep source assets and their `.import` metadata where Godot creates them.

## Build, Run, and Validation

Run commands from the repository root with Godot 4.7 available on `PATH` (or substitute the full executable path):

- `godot --path .` opens/runs the project.
- `godot --headless --path . --editor --quit` starts the editor headlessly, imports project assets, and checks editor-side loading/parsing.
- `godot --headless --path . --quit-after 5` launches the game briefly without a window; use this as a smoke test once a runnable main scene is configured.

Run `godot --headless --path . --script res://tests/player_movement_test.gd` to check mass, acceleration, friction, indicators, crate interaction, and jumping in `scenes/physics_test.tscn`. Tune the test scene via `scripts/physics_variables.gd`. Add automated checks alongside new gameplay systems and document their invocation here.

Run `godot --headless --path . --script res://tests/support_stability_test.gd` to check that the player remains stable on the crate.
Use the same command with `res://tests/crate_motion_test.gd` and `res://tests/respawn_test.gd` to check smooth movement on the crate and falling-body respawns.
Use `res://tests/jump_recoil_test.gd` to check jump impulse and momentum on a movable support.
Use `res://tests/air_correction_test.gd` to check the single air correction and its reset after landing.
Use `res://tests/landing_friction_test.gd` to check landing friction and retained horizontal motion.
Use `res://tests/wall_jump_test.gd` to check wall jumps on both sides.

## Style and Naming

Follow `.editorconfig` (UTF-8); use Godot/GDScript conventions: tabs for GDScript indentation, `snake_case.gd` files and functions, `PascalCase` for classes/nodes, and `UPPER_SNAKE_CASE` for constants. Use descriptive, domain-specific names and keep scripts focused. Prefer configuring project settings through Godot's editor when practical.

## Testing Changes

For each change, run the headless editor validation and inspect Godot's output for parse or import errors. For scene, input, or gameplay changes, also launch the project and manually verify the affected behavior in the editor/game. Do not claim runtime validation if no main scene is configured or the project cannot launch.

## Commits and Pull Requests

No Git history or established commit convention is available in this checkout. Use concise imperative commit subjects, optionally with a scope (for example, `player: add jump input`). PRs should explain the user-visible change, list validation performed, link related issues when applicable, and include screenshots or a short recording for visual changes.

## Configuration and Generated Files

Do not commit `.godot/` cache contents or generated exports. Keep project configuration changes focused and review `project.godot` diffs carefully. Do not add secrets, local machine paths, or credentials to the repository.
