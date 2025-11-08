# TowerUP

TowerUP is a 2D pixel-art tower defense management prototype built with Godot 4.4.1. The player acts as the weary custodian of a divine artillery tower, keeping it repaired, cooled, and stocked as endless waves of enemies approach from every direction.

## Project Structure

```
res://
├── CODEX_RULES.md          # Guardrails for GDScript development in this project
├── project.godot           # Godot project configuration (autoload + inputs)
├── scenes/
│   ├── battle/BattleScene.tscn      # Active wave gameplay (tower, enemies, lasso, loot)
│   ├── main_menu/StartMenu.tscn     # Campaign/Skirmish entry with options and quit controls
│   ├── main_menu/LetterModifierWarning.tscn  # Narrative letter prompt before waves
│   └── upgrade/UpgradeScene.tscn    # Intermission letter + upgrade selection
├── mobs/                            # Enemy archetype folders and texture stubs
└── scripts/
    ├── battle/battle_scene.gd       # Coordinates battle systems and wave flow
    ├── game_manager.gd              # Autoload singleton handling waves/resources
    ├── systems/                     # Modular gameplay systems (tower, lasso, loot, etc.)
    └── ui/                          # UI logic for menu and upgrade scenes
```

## Getting Started

1. Open the project in Godot 4.4.1.
2. Ensure `GameManager` is registered as an autoload (configured in `project.godot`).
3. Run the project — the main menu loads first. Start a new game to enter the battle scene, and survive a wave to preview the upgrade/letter flow.

## Design Pillars

- **Caretaker Fantasy**: The player is the engineer tending to the divine tower, not a direct combatant.
- **Signal-Driven Systems**: Tower, lasso, loot, crafting, and enemy spawner scripts communicate through signals to keep the code modular and extendable.
- **Narrative Letters**: Between waves, the player receives “Letters of War” from enemy generals that foreshadow modifiers for upcoming encounters.

This repository contains scaffolding for the game loop, ready for future content, art, audio, and minigame implementations.
