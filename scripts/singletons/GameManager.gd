extends Node
class_name GameManagerSingleton

const Constants := preload("res://scripts/constants.gd")
const WaveGenScript := preload("res://scripts/systems/WaveGen.gd")

const START_MENU_SCENE_PATH := "res://scenes/main_menu/StartMenu.tscn"
const LOADING_SCENE_PATH := "res://scenes/main_menu/LoadingScreen.tscn"
const LETTER_SCENE_PATH := "res://scenes/main_menu/LetterModifierWarning.tscn"
const UPGRADE_SCENE_PATH := "res://scenes/upgrade/UpgradeScene.tscn"
const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"

signal campaign_updated()
signal resources_updated()

var days_survived: int = 0
var difficulty_mult: float = 1.0
var resources: Dictionary = {
    Constants.LOOT_METAL: 0,
    Constants.LOOT_ESSENCE: 0
}
var tower_upgrades: Dictionary = {
    "damage_mult": 1.0,
    "heat_mult": 1.0,
    "hp_mult": 1.0,
    "ammo_mult": 1.0
}
var current_wave_spec: Array = []
var _letter_summary: Dictionary = {}

var _wave_generator: WaveGen = WaveGenScript.new()

func _ready() -> void:
    _configure_input_map()

func reset_campaign() -> void:
    days_survived = 0
    difficulty_mult = 1.0
    resources = {
        Constants.LOOT_METAL: 0,
        Constants.LOOT_ESSENCE: 0
    }
    tower_upgrades = {
        "damage_mult": 1.0,
        "heat_mult": 1.0,
        "hp_mult": 1.0,
        "ammo_mult": 1.0
    }
    current_wave_spec = []
    _letter_summary = {}
    campaign_updated.emit()
    resources_updated.emit()

func start_new_game() -> void:
    reset_campaign()
    print("[GameManager] New campaign initialized")
    enter_upgrade()

func on_loading_complete() -> void:
    if Engine.is_editor_hint():
        prepare_next_wave()
    show_letter_scene()

func show_letter_scene() -> void:
    _change_scene(LETTER_SCENE_PATH)

func enter_upgrade() -> void:
    _change_scene(UPGRADE_SCENE_PATH)

func enter_battle() -> void:
    _change_scene(BATTLE_SCENE_PATH)

func enter_loading_screen() -> void:
    _change_scene(LOADING_SCENE_PATH)

func return_to_start_menu() -> void:
    _change_scene(START_MENU_SCENE_PATH)

func advance_day() -> void:
    days_survived += 1
    difficulty_mult += 0.1
    campaign_updated.emit()

func prepare_next_wave() -> void:
    var day_index: int = days_survived
    var generator := get_wave_generator()
    var raw_spec: Array = generator.generate_wave(day_index)
    set_upcoming_wave(raw_spec)
    var letter: Dictionary = generator.build_letter(day_index, raw_spec)
    set_letter_summary(letter)

func set_upcoming_wave(spec: Array) -> void:
    current_wave_spec = []
    for entry in spec:
        if entry is Dictionary:
            current_wave_spec.append(_apply_difficulty_to_entry(entry.duplicate(true)))
    campaign_updated.emit()

func get_upcoming_wave() -> Array:
    var clone: Array = []
    for entry in current_wave_spec:
        if entry is Dictionary:
            clone.append(entry.duplicate(true))
    return clone

func set_letter_summary(data: Dictionary) -> void:
    _letter_summary = data.duplicate(true)

func get_letter_summary() -> Dictionary:
    return _letter_summary.duplicate(true)

func generate_wave_preview() -> Array:
    var raw_spec: Array = _wave_generator.generate_wave(days_survived)
    var adjusted: Array = []
    for entry in raw_spec:
        if entry is Dictionary:
            adjusted.append(_apply_difficulty_to_entry(entry.duplicate(true)))
    return adjusted

func get_wave_generator() -> WaveGen:
    return _wave_generator

func add_resource(id: String, amount: int) -> void:
    if not resources.has(id):
        resources[id] = 0
    resources[id] += amount
    resources_updated.emit()

func spend_resource(id: String, amount: int) -> bool:
    if resources.get(id, 0) < amount:
        return false
    resources[id] = resources.get(id, 0) - amount
    resources_updated.emit()
    return true

func add_resources_bulk(payload: Dictionary) -> void:
    for key in payload.keys():
        add_resource(String(key), int(payload[key]))

func get_resources() -> Dictionary:
    return resources.duplicate(true)

func apply_upgrade(id: String) -> void:
    match id:
        "reinforced_hull":
            tower_upgrades["hp_mult"] += 0.1
        "cooling_pipes":
            tower_upgrades["heat_mult"] = max(0.1, tower_upgrades["heat_mult"] - 0.1)
        "improved_coils":
            tower_upgrades["damage_mult"] += 0.1
        "extra_storage":
            tower_upgrades["ammo_mult"] += 0.05
        _:
            pass
    campaign_updated.emit()

func get_tower_upgrades() -> Dictionary:
    return tower_upgrades.duplicate(true)

func collect_battle_rewards(rewards: Dictionary) -> void:
    if rewards == null:
        return
    for key in rewards.keys():
        add_resource(String(key), int(rewards[key]))

func _apply_difficulty_to_entry(entry: Dictionary) -> Dictionary:
    var adjusted: Dictionary = entry.duplicate(true)
    adjusted["hp"] = float(adjusted.get("hp", 0.0)) * difficulty_mult
    adjusted["damage"] = float(adjusted.get("damage", 0.0)) * difficulty_mult
    adjusted["speed"] = float(adjusted.get("speed", 0.0)) * (1.0 + (difficulty_mult - 1.0) * 0.5)
    var count_scale: float = 1.0 + (difficulty_mult - 1.0) * 0.5
    adjusted["count"] = max(1, int(round(float(adjusted.get("count", 1)) * count_scale)))
    return adjusted

func _configure_input_map() -> void:
    _ensure_action("cool_action")
    _ensure_action("repair_action")
    _ensure_action("lasso_action")
    _add_key_to_action("cool_action", Key.KEY_C)
    _add_key_to_action("repair_action", Key.KEY_R)
    _add_mouse_button_to_action("lasso_action", MouseButton.MOUSE_BUTTON_LEFT)

func _ensure_action(action_name: String) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)

func _add_key_to_action(action_name: String, keycode: Key) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    if not InputMap.action_has_event(action_name, event):
        InputMap.action_add_event(action_name, event)

func _add_mouse_button_to_action(action_name: String, button: MouseButton) -> void:
    var event := InputEventMouseButton.new()
    event.button_index = button
    if not InputMap.action_has_event(action_name, event):
        InputMap.action_add_event(action_name, event)

func _change_scene(path: String) -> void:
    if path.is_empty():
        push_warning("Attempted to change to an empty scene path.")
        return
    if not ResourceLoader.exists(path):
        push_error("[GameManager] Scene path invalid: " + path)
        return
    var error_code := get_tree().change_scene_to_file(path)
    if error_code != OK:
        push_error("[GameManager] change_scene_to_file failed: " + str(error_code))
