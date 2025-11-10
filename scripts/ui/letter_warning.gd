extends Control

const Constants := preload("res://scripts/constants.gd")
const START_MENU_SCENE_PATH := "res://scenes/main_menu/StartMenu.tscn"
const AutoloadUtilsConst := preload("res://scripts/utils/autoload_utils.gd")
const GameManagerScript := preload("res://scripts/singletons/GameManager.gd")

@onready var commander_label: Label = $MarginContainer/Panel/VBoxContainer/CommanderLabel
@onready var message_label: RichTextLabel = $MarginContainer/Panel/VBoxContainer/MessageLabel
@onready var summary_label: Label = $MarginContainer/Panel/VBoxContainer/SummaryLabel
@onready var proceed_button: Button = $MarginContainer/Panel/VBoxContainer/ButtonRow/ProceedButton
@onready var back_button: Button = $MarginContainer/Panel/VBoxContainer/ButtonRow/BackButton

var _current_spec: Array = []
var _letter_data: Dictionary = {}

func _ready() -> void:
    proceed_button.pressed.connect(_on_proceed_pressed)
    back_button.pressed.connect(_on_back_pressed)
    _prepare_letter()

func _prepare_letter() -> void:
    var manager_node := AutoloadUtilsConst.get_autoload("GameManager")
    if not (manager_node is GameManagerScript):
        _populate_fallback_text()
        return
    var manager: GameManagerSingleton = manager_node as GameManagerSingleton
    var day_index: int = manager.days_survived
    var spec: Array = manager.get_upcoming_wave()
    if spec.is_empty():
        manager.prepare_next_wave()
        spec = manager.get_upcoming_wave()
    var letter: Dictionary = manager.get_letter_summary()
    if letter.is_empty():
        manager.prepare_next_wave()
        letter = manager.get_letter_summary()
    _current_spec = spec
    _letter_data = letter
    _display_letter(day_index, letter)

func _display_letter(day_index: int, letter: Dictionary) -> void:
    var commander: String = letter.get("commander", "Unknown Commander")
    var intro: String = letter.get("intro", "The enemy advances.")
    var modifier: String = letter.get("modifier", "")
    var summary: String = letter.get("summary", "")
    var wave_number: int = letter.get("wave_index", day_index + 1)
    var directions_raw: Array = letter.get("directions", [])
    var directions: Array[int] = []
    for value in directions_raw:
        directions.append(int(value))
    if summary.is_empty():
        var direction_names: Array[String] = []
        for value in directions:
            direction_names.append(Constants.get_direction_name(value))
        summary = "Assault from %s." % ", ".join(direction_names)
    commander_label.text = "Day %d — Commander %s" % [wave_number, commander]
    var body_lines: Array[String] = ["[center][b]Siege Dispatch[/b][/center]", intro]
    if not modifier.is_empty():
        body_lines.append("[i]%s[/i]" % modifier)
    message_label.text = "\n\n".join(body_lines)
    summary_label.text = summary

func _populate_fallback_text() -> void:
    commander_label.text = "Day 1 — Commander Unknown"
    message_label.text = "No campaign data available."
    summary_label.text = "Awaiting wave specifications."

func _on_proceed_pressed() -> void:
    print("[LetterWarning] PROCEED pressed")
    var manager_node := AutoloadUtilsConst.get_autoload("GameManager")
    if manager_node is GameManagerScript:
        var manager: GameManagerSingleton = manager_node as GameManagerSingleton
        manager.enter_battle()
    else:
        var battle_path := "res://scenes/battle/BattleScene.tscn"
        if ResourceLoader.exists(battle_path):
            var error_code := get_tree().change_scene_to_file(battle_path)
            if error_code != OK:
                push_error("[LetterWarning] Failed to change scene: " + str(error_code))
        else:
            push_error("[LetterWarning] Missing battle scene: " + battle_path)

func _on_back_pressed() -> void:
    print("[LetterWarning] BACK pressed")
    var manager_node := AutoloadUtilsConst.get_autoload("GameManager")
    if manager_node is GameManagerScript:
        var manager: GameManagerSingleton = manager_node as GameManagerSingleton
        manager.enter_upgrade()
    else:
        if ResourceLoader.exists(START_MENU_SCENE_PATH):
            var error_code := get_tree().change_scene_to_file(START_MENU_SCENE_PATH)
            if error_code != OK:
                push_error("[LetterWarning] Failed to change scene: " + str(error_code))
        else:
            push_error("[LetterWarning] Missing start menu scene: " + START_MENU_SCENE_PATH)
