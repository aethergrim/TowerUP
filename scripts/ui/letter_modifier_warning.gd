extends Control

const Constants := preload("res://scripts/constants.gd")
const START_MENU_SCENE_PATH := "res://scenes/main_menu/StartMenu.tscn"

@onready var commander_label: Label = $MarginContainer/Panel/VBoxContainer/CommanderLabel
@onready var message_label: RichTextLabel = $MarginContainer/Panel/VBoxContainer/MessageLabel
@onready var summary_label: Label = $MarginContainer/Panel/VBoxContainer/SummaryLabel
@onready var proceed_button: Button = $MarginContainer/Panel/VBoxContainer/ButtonRow/ProceedButton
@onready var back_button: Button = $MarginContainer/Panel/VBoxContainer/ButtonRow/BackButton

func _ready() -> void:
    proceed_button.pressed.connect(_on_proceed_pressed)
    back_button.pressed.connect(_on_back_pressed)
    _refresh_letter()

func _refresh_letter() -> void:
    if not Engine.has_singleton("GameManager"):
        commander_label.text = "Unknown Commander"
        message_label.text = "The signal network is silent."
        summary_label.text = "No wave data available."
        return
    var data: Dictionary = GameManager.get_current_letter_data()
    var commander: String = data.get("commander", "Unknown Commander")
    var intro: String = data.get("intro", "The enemy advances.")
    var modifier: String = data.get("modifier", "")
    var summary: String = data.get("summary", "")
    var wave_index: int = data.get("wave_index", GameManager.current_wave)
    commander_label.text = "Commander %s" % commander
    var body_lines: Array[String] = ["[center][b]Wave %d[/b][/center]" % wave_index, intro]
    if not modifier.is_empty():
        body_lines.append("[i]%s[/i]" % modifier)
    message_label.text = "\n".join(body_lines)
    if summary.is_empty():
        var fallback_dirs_raw: Array = data.get("directions", [])
        var fallback_dirs: Array[int] = []
        for value in fallback_dirs_raw:
            fallback_dirs.append(int(value))
        var fallback_texts: Array[String] = []
        for value in fallback_dirs:
            fallback_texts.append(Constants.get_direction_name(value))
        summary = "Attacks expected from %s." % ", ".join(fallback_texts)
    summary_label.text = summary

func _on_proceed_pressed() -> void:
    if Engine.has_singleton("GameManager"):
        GameManager.enter_battle()

func _on_back_pressed() -> void:
    if Engine.has_singleton("GameManager"):
        GameManager.return_to_start_menu()
    else:
        get_tree().change_scene_to_file(START_MENU_SCENE_PATH)
