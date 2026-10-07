# Football Career Simulator: Project Instructions

## Project Context

- This is a Godot 4.x football career simulation, PC-first with future mobile support. The project currently declares Godot 4.7 compatibility and uses the Compatibility renderer; check `project.godot` before relying on engine settings or version-specific APIs.
- The long-term game is an online, persistent football world. Real clubs and leagues should coexist with generated players and future generations. Players and clubs evolve over time, and the world continues simulating when the user's player is unavailable or not selected. Give the user's career the highest simulation detail and optimize distant simulation.
- Treat the product vision as direction, not proof that a feature exists. Implement one complete, testable feature at a time; do not build speculative future systems prematurely.

## Verified Current Baseline

- `scenes/main.tscn` is the configured entry scene. `SaveManager` is an autoload implemented in `scripts/save_manager.gd`.
- `data/player_data.gd` defines a `PlayerData` Resource with identity/body data, technical and mental attributes, potential bounds, and basic validity checks.
- `scenes/create_career.gd` gathers and validates a name, age, and nationality, then delegates profile generation to `systems/player_generator.gd`. `scenes/CareerDashboard.tscn` displays the active player's name, age, and nationality.
- `scripts/save_manager.gd` writes versioned player data to JSON, reconstructs `PlayerData` when loading, and migrates version-1 saves. `scenes/main.gd` does not create test player data; Continue opens the dashboard only after a successful load.
- `systems/` contains the player generator. `assets/` is currently empty. Recheck folders before extending them because this baseline can change.

## Arabic-First UI

- The first release is Arabic-first: player-facing UI text must be Arabic, and UI roots/layouts should use right-to-left direction where appropriate.
- Keep code identifiers, file names, class names, internal IDs, and stored implementation values in English. Do not show internal English values directly to players; map them to Arabic presentation text.
- Keep presentation strings separable from game logic so English localization can be added later. Do not introduce a full localization framework until a feature needs one.
- Use the project Theme in `ui/game_theme.tres` for reusable colors, typography, spacing, radii, and control styles. Prefer its theme variations and shared UI scenes over repeated per-screen styling.
- Keep layouts RTL-aware and container-based where practical. Do not show mock career information to fill empty space.

## Architecture and Godot Conventions

- Separate UI, data models, and simulation/game logic. Keep presentation scripts focused on input, display, and calling domain behavior; keep game rules out of UI scripts.
- Keep game data out of UI hardcoding. Use data resources/configuration or focused data providers as appropriate; avoid unnecessary abstractions for a single feature.
- Prefer reusable systems and components with clear ownership, and avoid duplicated rules or serialization mappings where a small shared helper is justified.
- Use snake_case for new script filenames, variables, functions, and signals; use PascalCase for classes and named types. Preserve existing paths and match resource path capitalization exactly. Do not rename existing files just for stylistic consistency.
- Use typed GDScript where it improves clarity and catches mistakes. Follow Godot 4 APIs and the project's configured renderer/settings. Keep scene node paths and signal method names synchronized when changing scenes or scripts.
- Do not put external AI APIs in the core simulation dependency chain.

## Football Simulation Rules

- The player starts around age 14. Player creation must not let the user choose overall rating, potential, starting club, or final position.
- Generate hidden potential in-game as a range, not a guaranteed final rating. Nationality should influence the starting football environment; position should emerge dynamically from attributes, manager decisions, tactics, squad needs, development, and match usage.
- Build development from relevant factors such as training, minutes, position, form, fitness, sharpness, manager trust, coach quality, injuries, discipline, experience, decisions, and environment. Do not collapse these into arbitrary UI-only bonuses.
- Track every match involving the player's team. Represent whether the player starts, substitutes in, remains unused, is unselected, or is unavailable. Base match ratings on match events.
- Full Simulation and Interactive Important Moments are future match modes. A text/2D presentation is suitable for an initial version; full 3D is not a prerequisite.
- Career history should be designed to track seasons, clubs, competitions, appearances, starts, minutes, goals, assists, ratings, trophies, awards, transfers, contracts, injuries, and important events as features are implemented.
- Real and generated players, club/league changes, transfers, promotions, and relegations belong to the long-term world simulation. Club creation/purchase is future scope.

## Saves and Online Features

- Preserve save compatibility whenever possible. For save schema changes, validate input, handle missing/older fields deliberately, and use the existing or an explicit schema version. Do not silently discard career data.
- Keep persistent career state separate from transient UI state. A load operation should restore validated domain data, not merely print it.
- Careers are primarily independent. Leaderboards, records, achievements, and Hall of Fame are future online features; design competitive records with server verification and anti-cheat in mind when that work begins.
- Monetization must never provide a competitive gameplay advantage.

## Change and Validation Workflow

- Make small, understandable, Git-friendly changes. Do not silently remove existing behavior or replace a working system without a clear architectural reason.
- Before editing, inspect the owning scene/script and its callers, signals, resource paths, and nearby behavior. State the intended behavior and a focused way to verify it.
- Keep each feature independently testable. Run the narrowest relevant available check after changes; inspect Godot diagnostics for modified scripts/scenes and report checks that could not be run. Do not claim runtime behavior is verified based only on static inspection.
- No test suite or build pipeline is currently established. Do not invent test commands; use available Godot/editor checks and add focused tests only when the feature and project setup support them.
- Avoid unrelated cleanup, generated `.godot/` cache changes, and broad refactors while implementing a feature.