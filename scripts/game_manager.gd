extends Node

const Constants := preload("res://scripts/constants.gd")

const START_MENU_SCENE_PATH := "res://scenes/main_menu/StartMenu.tscn"
const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"
const UPGRADE_SCENE_PATH := "res://scenes/upgrade/UpgradeScene.tscn"
const LETTER_SCENE_PATH := "res://scenes/main_menu/LetterModifierWarning.tscn"
const LOADING_SCENE_PATH := "res://scenes/main_menu/LoadingScreen.tscn"

const WaveLogic := preload("res://scripts/systems/wave_logic.gd")

var current_wave: int = 1
var resources: Dictionary = {
    Constants.LOOT_METAL: 0,
    Constants.LOOT_ESSENCE: 0
}
var current_config: Dictionary = {
    "spawn_dirs": [Constants.Dir.W],
    "count_by_tier": {Constants.EnemyTier.GRUNT: 4},
    "modifier": null
}
var pending_ammo: int = 0
var pending_cooling: float = 0.0
var last_wave_victory: bool = true
var current_wave_data: Dictionary = {}

var _wave_logic: Node = null

func _ready() -> void:
    _configure_input_map()
    _ensure_wave_logic()
    _prepare_wave_data()

func start_new_game() -> void:
    current_wave = 1
    resources = {
        Constants.LOOT_METAL: 0,
        Constants.LOOT_ESSENCE: 0
    }
    pending_ammo = 0
    pending_cooling = 0.0
    last_wave_victory = true
    _prepare_wave_data()
    _change_scene(LOADING_SCENE_PATH)

func continue_to_next_wave() -> void:
    current_wave += 1
    _prepare_wave_data()
    show_letter_scene()

func enter_battle() -> void:
    _change_scene(BATTLE_SCENE_PATH)

func report_wave_complete(result: Dictionary) -> void:
    var resource_payload: Dictionary = {}
    if result.has("resources") and result["resources"] is Dictionary:
        resource_payload = result["resources"]
    else:
        resource_payload = result
    for key in resource_payload.keys():
        if not resources.has(key):
            resources[key] = 0
        resources[key] += int(resource_payload[key])
    var victory: bool = true
    if result.has("victory"):
        victory = bool(result["victory"])
    last_wave_victory = victory
    _change_scene(UPGRADE_SCENE_PATH)

func get_current_wave_config() -> Dictionary:
    return current_config.duplicate(true)

func get_current_letter_data() -> Dictionary:
    return current_wave_data.get("letter", {}).duplicate(true)

func get_resources() -> Dictionary:
    return resources.duplicate(true)

func spend_resources(cost: Dictionary) -> bool:
    for key in cost.keys():
        if resources.get(key, 0) < int(cost[key]):
            return false
    for key in cost.keys():
        resources[key] = resources.get(key, 0) - int(cost[key])
    return true

func add_resource(resource_key: String, amount: int) -> void:
    if not resources.has(resource_key):
        resources[resource_key] = 0
    resources[resource_key] += amount

func add_pending_ammo(amount: int) -> void:
    pending_ammo += amount

func consume_pending_ammo() -> int:
    var amount: int = pending_ammo
    pending_ammo = 0
    return amount

func add_pending_cooling(amount: float) -> void:
    pending_cooling += amount

func consume_pending_cooling() -> float:
    var amount: float = pending_cooling
    pending_cooling = 0.0
    return amount

func show_letter_scene() -> void:
    _change_scene(LETTER_SCENE_PATH)

func on_loading_complete() -> void:
    show_letter_scene()

func return_to_start_menu() -> void:
    _change_scene(START_MENU_SCENE_PATH)

func _ensure_wave_logic() -> void:
    if _wave_logic == null:
        _wave_logic = WaveLogic.new()

func _prepare_wave_data() -> void:
    _ensure_wave_logic()
    current_wave_data = _wave_logic.generate_wave(current_wave, last_wave_victory)
    current_config = current_wave_data.get("config", current_config).duplicate(true)

func _configure_input_map() -> void:
    _ensure_action("cool_action")
    _ensure_action("repair_action")
    _add_key_to_action("cool_action", Key.KEY_C)
    _add_key_to_action("repair_action", Key.KEY_R)

func _ensure_action(action_name: String) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)

func _add_key_to_action(action_name: String, keycode: Key) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    if not InputMap.action_has_event(action_name, event):
        InputMap.action_add_event(action_name, event)

func _change_scene(path: String) -> void:
    if path.is_empty():
        push_warning("Attempted to change to an empty scene path.")
        return
    var scene: PackedScene = load(path)
    if scene:
        get_tree().change_scene_to_packed(scene)
    else:
        push_warning("Failed to load scene: %s" % path)
