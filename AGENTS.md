# CODEX_RULES.md — Godot 4.4.1 / GDScript Guardrails for Codex

> Drop this file in the repo root. Codex should read and obey these constraints.
> Purpose: eliminate common Codex→GDScript failure modes (typing, placeholders, scene IDs, load order).

## 0) Target & Constraints
- **Engine**: Godot **4.4.1** (GDScript 2.0).
- **Language**: GDScript (no Python syntax/semantics).
- **Files Codex may edit/create**: `.gd`, `.tscn`, `.tres`, `.cfg`, `.md`, `.json`. **Do NOT** generate binary `.res` or assets.
- **Project structure**: Prefer engine code under `addons/` when building a reusable template.
- **Build style**: Incremental. Ensure the project **compiles after each step** before continuing.

## 1) GDScript 4.x Syntax Rules (hard requirements)
1. Use `@export`, `@onready`, typed signals, and Godot 4 key/mouse constants:
   - `@export var speed: float = 3.0`
   - `@onready var label: Label = $Label`
   - `signal item_added(id: String)`
   - `KEY_ESCAPE`, `MOUSE_BUTTON_LEFT` (not `Key.ESCAPE`, not Godot 3 names)
2. **Never** use Python placeholders or ellipses:
   - Forbidden: `.` or `...` on their own line.
   - Use comments: `# TODO: implement`
3. Timers/await:
   - `await get_tree().create_timer(0.25).timeout`
4. Typed arrays/dicts and empty initializers:
   - `var data: Dictionary = {}`
   - `var items: Array = []` or `var names: Array[String] = []`
   - `var pos: Vector3 = Vector3.ZERO`
5. Avoid global wildcard imports; use `preload()` or `load()` for resources/scripts as needed.

## 2) Scene/Text Resource Editing Rules
1. When editing `.tscn` / `.tres`:
   - **Preserve** existing `[ext_resource]` IDs; do not renumber.
   - Keep node names stable unless explicitly instructed to rename.
   - Ensure signal connections reference **existing** method names.
2. When attaching scripts in `.tscn`, ensure the file path exists and compiles.
3. For new scenes:
   - Start with a minimal valid header: `[gd_scene format=3]` (plus `load_steps`/`uid` if present).
   - Only introduce `[ext_resource]` blocks that you actually use.

## 3) Signals & Connections
1. If you connect a signal, you **must**:
   - Declare the signal on the emitting script, e.g. `signal used(target: Node)`.
   - Implement the handler method on the receiver with a matching signature.
2. Use Godot 4 connection style:
   - `button.pressed.connect(_on_pressed)` or `button.pressed.connect(Callable(self, "_on_pressed"))`

## 4) Autoloads & Dependencies
1. No cross-autoload dependencies until all referenced scripts **compile**.
2. Keep systems loosely coupled. For optional calls, gate them:
   ```gdscript
   if Engine.has_singleton("Game"):
       Game.some_method()
   ```
3. Avoid referencing classes by `class_name` unless unique and already compiled.

## 5) Incremental Build Order (apply in multi-file tasks)
1. Core singletons (e.g., `Game.gd`) — compile.
2. Player/controller scripts — compile.
3. Interactable base + sample interactables — compile.
4. UI scenes/scripts — compile.
5. Higher-level systems (inventory, quests) — compile.
6. Mini-games or feature scenes — compile.
> After each step: re-check that the project compiles before proceeding.

## 6) Validation & Diagnostics (must run before finishing)
At the end of the task, ensure **zero parse errors**. Perform all of the below:
- Open/parse every `.gd`, `.tscn`, and `.tres` you created or modified.
- Re-check that there are **no** untyped empty containers at class scope (`= {}`, `= []`).
- Ensure no lines containing standalone `.` or `...` exist.
- Ensure all connected signals have corresponding declarations & handlers.

*(Optional) Provide a short summary listing files changed and any new signals introduced.*

## 7) Commit & Report Policy
- Group changes into a single coherent commit when possible.
- Include a summary with:
  - Files created, files modified.
  - New signals and their handlers.
  - Any project setting changes (e.g., `run/main_scene`).

## 8) Definition of Done (DoD)
- Project compiles in Godot 4.4.1; no red errors in the Output panel on launch.
- All edited scenes open in the editor without missing resources.
- All new scripts parse; no “Cannot infer type …” caused by empty literals.
- No forbidden placeholders (`.` / `...`). No outdated enums (`Key.ESCAPE`, etc.).

---

## Task Header Template (paste at the top of future Codex tasks)

**Task Context**
- Engine: Godot 4.4.1 (GDScript)
- Guardrails: obey `CODEX_RULES.md` in repo root

**Task Goal**
> _Describe the specific feature or refactor._

**Acceptance Criteria**
- [ ] Compiles after step N (incremental).
- [ ] Signals declared + handlers implemented.
- [ ] No untyped empty arrays/dicts.
- [ ] `.tscn` edits preserve ext_resource IDs.
- [ ] Summary of changes included.

**Out-of-Scope**
- Binary assets, `.res` files, non-Godot formats not listed in rules.

**Validation**
- Run syntax/parse checks across the changed files.
- Confirm no placeholders and correct enums/exports.

---

## Quick Reference (common pitfalls)
- Wrong enums: use `KEY_*`, `MOUSE_BUTTON_*`.
- Use `@export` (not `export var`).
- Use `@onready` (not `_ready`-time `$` without caching if used frequently).
- Typed signals if you pass arguments.
- Keep node paths stable or update all references.
