# TowerUP

TowerUP is a 2D pixel-art tower defense management prototype built with Godot 4.4.1. The player acts as the weary custodian of a divine artillery tower, keeping it repaired, cooled, and stocked as endless waves of enemies approach from every direction.

## Project Structure

```
res://
├── CODEX_RULES.md          # Guardrails for GDScript development in this project
├── project.godot           # Godot project configuration (autoload + inputs)
├── scenes/
│   ├── battle/
│   │   ├── BattleScene.tscn         # Active wave gameplay with camera + HUD
│   │   ├── Tower.tscn               # Tower core scene with health/heat logic
│   │   ├── Enemy.tscn               # Generic enemy body used by the spawner tiers
│   │   └── Loot.tscn                # Collectable resources spawned on enemy defeat
│   ├── main_menu/StartMenu.tscn     # Campaign/Skirmish entry with options and quit controls
│   ├── main_menu/LetterModifierWarning.tscn  # Narrative letter prompt before waves
│   └── upgrade/UpgradeScene.tscn    # Intermission letter + upgrade selection
├── mobs/                            # Enemy archetype folders and texture stubs
└── scripts/
    ├── battle/battle_scene.gd       # Coordinates battle systems, tower state, and wave flow
    ├── game_manager.gd              # Autoload singleton handling waves/resources
    ├── systems/                     # Modular gameplay systems (tower, lasso, loot, etc.)
    └── ui/                          # UI logic for menu and upgrade scenes
```

## Getting Started

1. Open the project in Godot 4.4.1.
2. Ensure `GameManager` is registered as an autoload (configured in `project.godot`).
3. Run the project — the main menu loads first. Start a new game to enter the battle scene where the tower now has visible HP, heat, and ammo readouts. Clear a wave (or fall in battle) to enter the upgrade/letter flow and prepare for the next assault.

## Design Pillars

- **Caretaker Fantasy**: The player is the engineer tending to the divine tower, not a direct combatant.
- **Signal-Driven Systems**: Tower, lasso, loot, crafting, and enemy spawner scripts communicate through signals to keep the code modular and extendable.
- **Narrative Letters**: Between waves, the player receives “Letters of War” from enemy generals that foreshadow modifiers for upcoming encounters.

This repository contains scaffolding for the game loop, ready for future content, art, audio, and minigame implementations.
