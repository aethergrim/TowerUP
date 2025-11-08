extends Node

signal wave_started(wave_index: int)
signal wave_completed(wave_index: int)
signal resources_updated(resources: Dictionary)
signal modifiers_updated(modifiers: Array[String])

enum Phase { MAIN_MENU, BATTLE, UPGRADE }

@export var max_waves: int = 12

var wave_index: int = 1
var phase: Phase = Phase.MAIN_MENU
var resources: Dictionary = {
    "metal": 0,
    "crystal": 0,
    "essence": 0
}
var active_letter: String = ""
var modifiers: Array[String] = []

func _ready() -> void:
    phase = Phase.MAIN_MENU

func start_new_game() -> void:
    wave_index = 1
    phase = Phase.BATTLE
    resources = {
        "metal": 0,
        "crystal": 0,
        "essence": 0
    }
    modifiers.clear()
    active_letter = ""
    _change_to_battle_scene()

func continue_to_next_wave() -> void:
    wave_index = min(wave_index + 1, max_waves)
    phase = Phase.BATTLE
    _change_to_battle_scene()

func return_to_main_menu() -> void:
    phase = Phase.MAIN_MENU
    var scene: PackedScene = load("res://scenes/main_menu/LetterModifierWarning.tscn")
    if scene:
        get_tree().change_scene_to_packed(scene)

func report_wave_complete(collected_resources: Dictionary, letter_text: String, new_modifiers: Array[String]) -> void:
    wave_completed.emit(wave_index)
    _apply_resources(collected_resources)
    active_letter = letter_text
    modifiers = new_modifiers
    modifiers_updated.emit(modifiers)
    phase = Phase.UPGRADE
    _change_to_upgrade_scene()

func _apply_resources(collected_resources: Dictionary) -> void:
    for key in collected_resources.keys():
        if not resources.has(key):
            resources[key] = 0
        resources[key] += int(collected_resources[key])
    resources_updated.emit(resources)

func spend_resources(cost: Dictionary) -> bool:
    for key in cost.keys():
        if resources.get(key, 0) < int(cost[key]):
            return false
    for key in cost.keys():
        resources[key] = resources.get(key, 0) - int(cost[key])
    resources_updated.emit(resources)
    return true

func get_letter_text() -> String:
    return active_letter

func get_modifiers() -> Array[String]:
    return modifiers.duplicate()

func _change_to_battle_scene() -> void:
    var scene: PackedScene = load("res://scenes/battle/BattleScene.tscn")
    if scene:
        get_tree().change_scene_to_packed(scene)
    call_deferred("_emit_wave_started")

func _emit_wave_started() -> void:
    wave_started.emit(wave_index)

func _change_to_upgrade_scene() -> void:
    var scene: PackedScene = load("res://scenes/upgrade/UpgradeScene.tscn")
    if scene:
        get_tree().change_scene_to_packed(scene)
