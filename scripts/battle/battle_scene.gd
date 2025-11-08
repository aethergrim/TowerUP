extends Node2D

const Constants := preload("res://scripts/constants.gd")

@onready var tower: Node2D = $Tower
@onready var enemy_spawner: Node2D = $EnemySpawner
@onready var loot_system: Node2D = $LootSystem
@onready var lasso: Node2D = $Lasso
@onready var crafting_system: Node = $CraftingSystem
@onready var repair_heat_system: Node = $RepairHeatSystem
@onready var status_label: Label = $HUD/MarginContainer/VBoxContainer/StatusLabel
@onready var hint_label: Label = $HUD/MarginContainer/VBoxContainer/HintLabel
@onready var debug_end_button: Button = $HUD/MarginContainer/VBoxContainer/DebugEndButton
@onready var game_over_ui: Control = $GameOver

var _collected_resources: Dictionary = {
    Constants.LOOT_METAL: 0,
    Constants.LOOT_ESSENCE: 0
}
var _tower_alive: bool = true
var _wave_reported: bool = false
var _game_over_active: bool = false

func _ready() -> void:
    var tree := get_tree()
    if tree:
        tree.paused = false
    _reset_resources()
    if tower and repair_heat_system.has_method("register_tower"):
        repair_heat_system.register_tower(tower)
    if enemy_spawner.has_method("set_target") and tower:
        enemy_spawner.set_target(tower)
    _connect_signals()
    _apply_pending_upgrades()
    _begin_wave()
    _update_status_text()
    if debug_end_button:
        debug_end_button.pressed.connect(_on_debug_end_pressed)
    if game_over_ui and game_over_ui.has_method("hide_game_over"):
        game_over_ui.hide_game_over()

func _process(_delta: float) -> void:
    _update_status_text()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if not tower:
            return
        if event.keycode == KEY_F1 and tower.has_method("add_ammo"):
            tower.add_ammo(10)
        elif event.keycode == KEY_F2 and tower.has_method("cool_by"):
            tower.cool_by(50.0)

func _connect_signals() -> void:
    if lasso.has_signal("loot_collected"):
        lasso.loot_collected.connect(_on_lasso_loot_collected)
    if loot_system.has_signal("loot_claimed"):
        loot_system.loot_claimed.connect(_on_loot_claimed)
    if crafting_system.has_signal("ammo_generated"):
        crafting_system.ammo_generated.connect(_on_ammo_generated)
    if crafting_system.has_signal("cooling_requested"):
        crafting_system.cooling_requested.connect(_on_cooling_requested)
    if enemy_spawner.has_signal("enemy_defeated"):
        enemy_spawner.enemy_defeated.connect(_on_enemy_defeated)
    if enemy_spawner.has_signal("wave_cleared"):
        enemy_spawner.wave_cleared.connect(_on_wave_cleared)
    if tower:
        if tower.has_signal("health_depleted"):
            tower.health_depleted.connect(_on_tower_destroyed)
        if tower.has_signal("health_changed"):
            tower.health_changed.connect(_on_tower_health_changed)

func _begin_wave() -> void:
    var config: Dictionary = {
        "spawn_dirs": [Constants.Dir.W],
        "count_by_tier": {Constants.EnemyTier.GRUNT: 4},
        "modifier": null
    }
    if Engine.has_singleton("GameManager"):
        config = GameManager.get_current_wave_config()
    if enemy_spawner.has_method("start_wave"):
        enemy_spawner.start_wave(config)

func _apply_pending_upgrades() -> void:
    if not Engine.has_singleton("GameManager"):
        return
    var bonus_ammo: int = GameManager.consume_pending_ammo()
    if bonus_ammo > 0 and tower and tower.has_method("add_ammo"):
        tower.add_ammo(bonus_ammo)
    var bonus_cooling: float = GameManager.consume_pending_cooling()
    if bonus_cooling > 0.0 and tower and tower.has_method("cool_by"):
        tower.cool_by(bonus_cooling)

func _reset_resources() -> void:
    _collected_resources[Constants.LOOT_METAL] = 0
    _collected_resources[Constants.LOOT_ESSENCE] = 0
    _tower_alive = true
    _wave_reported = false
    _game_over_active = false
    if debug_end_button:
        debug_end_button.disabled = false

func _on_enemy_defeated(_enemy: Node2D, tier: int, drop_world_position: Vector2) -> void:
    var loot_type: String = Constants.LOOT_METAL
    if tier == Constants.EnemyTier.RUSHER:
        loot_type = Constants.LOOT_ESSENCE
    elif tier == Constants.EnemyTier.TANK:
        loot_type = Constants.LOOT_METAL
    if loot_system.has_method("spawn_loot"):
        loot_system.spawn_loot(drop_world_position, loot_type)

func _on_lasso_loot_collected(loot_type: String) -> void:
    if crafting_system.has_method("process_loot"):
        crafting_system.process_loot(loot_type)

func _on_loot_claimed(loot_type: String) -> void:
    if _collected_resources.has(loot_type):
        _collected_resources[loot_type] += 1
    else:
        _collected_resources[loot_type] = 1

func _on_ammo_generated(amount: int) -> void:
    if tower and tower.has_method("add_ammo"):
        tower.add_ammo(amount)

func _on_cooling_requested(amount: float) -> void:
    if tower and tower.has_method("cool_by"):
        tower.cool_by(amount)

func _on_wave_cleared() -> void:
    if not _tower_alive or _wave_reported:
        return
    _finish_wave(true)

func _update_status_text() -> void:
    var wave_index: int = 1
    if Engine.has_singleton("GameManager"):
        wave_index = GameManager.current_wave
    var ammo_value: int = 0
    var heat_value: float = 0.0
    var max_heat: float = 0.0
    var health_value: float = 0.0
    var max_health: float = 0.0
    if tower:
        var ammo_variant = tower.get("ammo")
        if ammo_variant != null:
            ammo_value = int(ammo_variant)
        var heat_variant = tower.get("heat")
        if heat_variant != null:
            heat_value = float(heat_variant)
        var max_heat_variant = tower.get("max_heat")
        if max_heat_variant != null:
            max_heat = float(max_heat_variant)
        var health_variant = tower.get("health")
        if health_variant != null:
            health_value = float(health_variant)
        var max_health_variant = tower.get("max_health")
        if max_health_variant != null:
            max_health = float(max_health_variant)
    var status := "Wave: %d\nAmmo: %d\nHeat: %.1f / %.1f" % [
        wave_index,
        ammo_value,
        heat_value,
        max_heat
    ]
    if max_health > 0.0:
        status += "\nHP: %.0f / %.0f" % [health_value, max_health]
    status_label.text = status
    hint_label.text = "Lasso: LMB | Cool: C | Repair: R | Cheats: F1 Ammo / F2 Cool"

func _on_tower_destroyed() -> void:
    if not _tower_alive or _game_over_active:
        return
    _tower_alive = false
    _game_over_active = true
    if debug_end_button:
        debug_end_button.disabled = true
    if enemy_spawner.has_method("cancel_spawning"):
        enemy_spawner.cancel_spawning()
    if game_over_ui and game_over_ui.has_method("show_game_over"):
        game_over_ui.show_game_over()
    _wave_reported = true

func _on_tower_health_changed(_current: float, _maximum: float) -> void:
    _update_status_text()

func _on_debug_end_pressed() -> void:
    if _tower_alive and not _wave_reported:
        _finish_wave(true)

func _finish_wave(victory: bool) -> void:
    if _wave_reported:
        return
    _wave_reported = true
    if Engine.has_singleton("GameManager"):
        GameManager.report_wave_complete({
            "resources": _collected_resources.duplicate(),
            "victory": victory
        })
