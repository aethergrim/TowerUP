# TowerUP

TowerUP is a 2D pixel-art tower defense management prototype built with Godot 4.4.1. The player acts as the weary custodian of a divine artillery tower, keeping it repaired, cooled, and stocked as endless waves of enemies approach from every direction.

## Project Structure

```
res://
├── CODEX_RULES.md          # Guardrails for GDScript development in this project
├── project.godot           # Godot project configuration (autoload + inputs)
├── scenes/
│   ├── battle/
│   │   ├── BattleScene.tscn         # Active wave gameplay with camera + HUD overlays
│   │   ├── Tower.tscn               # Tower core scene with health/heat logic
│   │   ├── Enemy.tscn               # Generic enemy body used by the spawner
│   │   ├── TowerProjectile.tscn     # Visualized tower shots toward enemies
│   │   ├── Loot.tscn                # Collectable resources spawned on enemy defeat
│   │   ├── GameOver.tscn            # Overlay shown when the tower is destroyed
│   │   └── VictoryPanel.tscn        # Post-wave summary with loot + kill recap
│   ├── main_menu/
│   │   ├── StartMenu.tscn           # Campaign entry with options and quit controls
│   │   ├── LoadingScreen.tscn       # Preloads scenes while the next wave is prepared
│   │   └── LetterModifierWarning.tscn  # Letter briefing summarizing the next wave
│   └── upgrade/UpgradeScene.tscn    # Intermission upgrades between waves
├── mobs/                            # Enemy archetype folders and texture stubs
└── scripts/
    ├── battle/                      # Battlefield behaviours (enemy, projectile, scene controller)
    ├── data/                        # Enemy templates and affix definitions for wave generation
    ├── singletons/GameManager.gd    # Autoload singleton handling campaign state and scene flow
    ├── systems/                     # Modular systems (tower core, WaveGen, loot, lasso, etc.)
    └── ui/                          # UI logic for menus, loading, letter, and upgrade scenes
```

## Getting Started

1. Open the project in Godot 4.4.1.
2. Ensure `GameManager` is registered as an autoload (configured in `project.godot`).
3. Run the project — the main menu loads first. Starting a new campaign routes you to the upgrade bay, then the loading screen prepares the next wave before you read the latest letter, deploy into battle, and either fall (Game Over) or review the victory panel before returning for upgrades.

## Design Pillars

- **Caretaker Fantasy**: The player is the engineer tending to the divine tower, not a direct combatant.
- **Signal-Driven Systems**: Tower, lasso, loot, crafting, and enemy spawner scripts communicate through signals to keep the code modular and extendable.
- **Narrative Letters**: Between waves, the player receives “Letters of War” from enemy generals that foreshadow modifiers for upcoming encounters.

This repository contains scaffolding for the game loop, ready for future content, art, audio, and minigame implementations.
