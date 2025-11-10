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
@onready var victory_panel: CanvasLayer = $VictoryPanel

var _collected_resources: Dictionary = {
    Constants.LOOT_METAL: 0,
    Constants.LOOT_ESSENCE: 0
}
var _wave_finished: bool = false
var _kill_counts: Dictionary = {}
var _game_manager: GameManager = null

func _ready() -> void:
    var tree := get_tree()
    if tree:
        tree.paused = false
    _reset_state()
    _game_manager = _get_game_manager()
    _register_tower_with_systems()
    _connect_signals()
    _apply_upgrade_profile()
    _begin_wave()
    _update_status_text()

func _process(_delta: float) -> void:
    _update_status_text()

func _reset_state() -> void:
    _collected_resources[Constants.LOOT_METAL] = 0
    _collected_resources[Constants.LOOT_ESSENCE] = 0
    _wave_finished = false
    _kill_counts.clear()
    if debug_end_button:
        debug_end_button.disabled = false
    if game_over_ui and game_over_ui.has_method("hide_game_over"):
        game_over_ui.hide_game_over()
    if victory_panel and victory_panel.has_method("hide_victory"):
        victory_panel.hide_victory()

func _register_tower_with_systems() -> void:
    if repair_heat_system and repair_heat_system.has_method("register_tower"):
        repair_heat_system.register_tower(tower)

func _connect_signals() -> void:
    if lasso and lasso.has_signal("loot_collected"):
        lasso.loot_collected.connect(_on_lasso_loot_collected)
    if loot_system and loot_system.has_signal("loot_claimed"):
        loot_system.loot_claimed.connect(_on_loot_claimed)
    if crafting_system:
        if crafting_system.has_signal("ammo_generated"):
            crafting_system.ammo_generated.connect(_on_ammo_generated)
        if crafting_system.has_signal("cooling_requested"):
            crafting_system.cooling_requested.connect(_on_cooling_requested)
    if enemy_spawner:
        if enemy_spawner.has_signal("enemy_defeated"):
            enemy_spawner.enemy_defeated.connect(_on_enemy_defeated)
        if enemy_spawner.has_signal("wave_cleared"):
            enemy_spawner.wave_cleared.connect(_on_wave_cleared)
    if tower:
        if tower.has_signal("health_depleted"):
            tower.health_depleted.connect(_on_tower_destroyed)
        if tower.has_signal("health_changed"):
            tower.health_changed.connect(_on_tower_health_changed)
    if debug_end_button:
        debug_end_button.pressed.connect(_on_debug_end_pressed)

func _apply_upgrade_profile() -> void:
    if not tower:
        return
    var manager := _ensure_game_manager()
    if manager == null:
        return
    var upgrades: Dictionary = manager.get_tower_upgrades()
    if tower.has_method("apply_upgrade_profile"):
        tower.apply_upgrade_profile(upgrades)

func _begin_wave() -> void:
    var spec: Array = []
    var manager := _ensure_game_manager()
    if manager:
        spec = manager.get_upcoming_wave()
    if spec.is_empty():
        if manager:
            var generator = manager.get_wave_generator()
            spec = generator.generate_wave(manager.days_survived)
            manager.set_upcoming_wave(spec)
            spec = manager.get_upcoming_wave()
    if enemy_spawner and enemy_spawner.has_method("start_wave"):
        enemy_spawner.start_wave(spec, tower)

func _update_status_text() -> void:
    var day_number: int = 1
    var manager := _ensure_game_manager()
    if manager:
        day_number = manager.days_survived + 1
    var ammo_value: int = 0
    var heat_value: float = 0.0
    var max_heat: float = 0.0
    var health_value: float = 0.0
    var max_health: float = 0.0
    if tower:
        ammo_value = int(tower.get("ammo"))
        heat_value = float(tower.get("heat"))
        max_heat = float(tower.get("max_heat"))
        health_value = float(tower.get("health"))
        max_health = float(tower.get("max_health"))
    var metal: int = _collected_resources.get(Constants.LOOT_METAL, 0)
    var essence: int = _collected_resources.get(Constants.LOOT_ESSENCE, 0)
    var status_lines: Array[String] = [
        "Day %d" % day_number,
        "Ammo: %d" % ammo_value,
        "Heat: %.1f / %.1f" % [heat_value, max_heat],
        "HP: %.0f / %.0f" % [health_value, max_health],
        "Loot — Metal: %d | Essence: %d" % [metal, essence]
    ]
    status_label.text = "\n".join(status_lines)
    hint_label.text = "Lasso: LMB | Cool: C | Repair: R"

func _on_lasso_loot_collected(loot_type: String) -> void:
    if crafting_system and crafting_system.has_method("process_loot"):
        crafting_system.process_loot(loot_type)

func _on_loot_claimed(loot_type: String) -> void:
    if _collected_resources.has(loot_type):
        _collected_resources[loot_type] += 1
    else:
        _collected_resources[loot_type] = 1
    if loot_type == Constants.LOOT_METAL and tower and tower.has_method("add_ammo"):
        tower.add_ammo(1)
    elif loot_type == Constants.LOOT_ESSENCE and tower and tower.has_method("cool_by"):
        tower.cool_by(5.0)

func _on_enemy_defeated(enemy_position: Vector2, loot: Dictionary, template_id: String) -> void:
    if not template_id.is_empty():
        var current: int = int(_kill_counts.get(template_id, 0))
        _kill_counts[template_id] = current + 1
    for key in loot.keys():
        var loot_id: String = String(key)
        var amount: int = int(loot[key])
        for _i in range(amount):
            if loot_system and loot_system.has_method("spawn_loot"):
                loot_system.spawn_loot(enemy_position, loot_id)

func _on_ammo_generated(amount: int) -> void:
    if tower and tower.has_method("add_ammo"):
        tower.add_ammo(amount)

func _on_cooling_requested(amount: float) -> void:
    if tower and tower.has_method("cool_by"):
        tower.cool_by(amount)

func _on_wave_cleared() -> void:
    if _wave_finished:
        return
    call_deferred("_finish_wave", true)

func _on_tower_destroyed() -> void:
    if _wave_finished:
        return
    if debug_end_button:
        debug_end_button.disabled = true
    if enemy_spawner and enemy_spawner.has_method("cancel_spawning"):
        enemy_spawner.cancel_spawning()
    if game_over_ui and game_over_ui.has_method("show_game_over"):
        game_over_ui.show_game_over()
    _finish_wave(false)

func _on_tower_health_changed(_current: float, _maximum: float) -> void:
    _update_status_text()

func _on_debug_end_pressed() -> void:
    if not _wave_finished:
        call_deferred("_finish_wave", true)

func _finish_wave(victory: bool) -> void:
    if _wave_finished:
        return
    _wave_finished = true
    if debug_end_button:
        debug_end_button.disabled = true
    if enemy_spawner and enemy_spawner.has_method("cancel_spawning"):
        enemy_spawner.cancel_spawning()
    var manager := _ensure_game_manager()
    if manager == null:
        if victory:
            _show_victory_panel({})
        else:
            get_tree().change_scene_to_file("res://scenes/main_menu/StartMenu.tscn")
        return
    if victory:
        var completed_day: int = manager.days_survived + 1
        var summary := _build_victory_summary(completed_day)
        manager.collect_battle_rewards(_collected_resources.duplicate())
        manager.advance_day()
        if not _show_victory_panel(summary):
            manager.enter_upgrade()
    else:
        if game_over_ui != null:
            return
        call_deferred("_request_defeat_transition")

func _request_defeat_transition() -> void:
    var manager := _ensure_game_manager()
    if manager:
        manager.return_to_start_menu()
    else:
        get_tree().change_scene_to_file("res://scenes/main_menu/StartMenu.tscn")

func _build_victory_summary(completed_day: int) -> Dictionary:
    var commanders: Array[String] = []
    var manager := _ensure_game_manager()
    var letter: Dictionary = {}
    if manager:
        letter = manager.get_letter_summary()
    var commander_name: String = letter.get("commander", "Unknown Commander")
    if not commander_name.is_empty():
        commanders.append(commander_name)
    return {
        "completed_day": completed_day,
        "commanders": commanders,
        "kills": _kill_counts.duplicate(true),
        "resources": _collected_resources.duplicate(true)
    }

func _show_victory_panel(summary: Dictionary) -> bool:
    if victory_panel == null:
        var manager := _ensure_game_manager()
        if manager:
            manager.enter_upgrade()
        return true
    if victory_panel.has_method("show_victory"):
        victory_panel.show_victory(summary)
        return true
    victory_panel.visible = true
    return true

func _get_game_manager() -> GameManager:
    if Engine.has_singleton("GameManager"):
        return GameManager
    return null

func _ensure_game_manager() -> GameManager:
    if _game_manager == null:
        _game_manager = _get_game_manager()
    return _game_manager
