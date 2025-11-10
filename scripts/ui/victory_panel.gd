extends CanvasLayer

const START_MENU_SCENE_PATH := "res://scenes/main_menu/StartMenu.tscn"

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var commander_label: Label = $Panel/MarginContainer/VBoxContainer/CommanderLabel
@onready var kills_label: Label = $Panel/MarginContainer/VBoxContainer/KillsLabel
@onready var resources_label: Label = $Panel/MarginContainer/VBoxContainer/ResourcesLabel
@onready var continue_button: Button = $Panel/MarginContainer/VBoxContainer/ContinueButton

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    if continue_button:
        continue_button.pressed.connect(_on_continue_pressed)

func show_victory(summary: Dictionary) -> void:
    var tree := get_tree()
    if tree:
        tree.paused = true
    visible = true
    _populate_fields(summary)
    if continue_button:
        continue_button.grab_focus()

func hide_victory() -> void:
    visible = false
    var tree := get_tree()
    if tree:
        tree.paused = false

func _populate_fields(summary: Dictionary) -> void:
    var completed_day: int = int(summary.get("completed_day", 1))
    title_label.text = "VICTORY — Day %d" % completed_day
    var commanders: Array = summary.get("commanders", [])
    if commanders.is_empty():
        commander_label.text = "Commanders Routed: Unknown"
    else:
        var names: Array[String] = []
        for commander in commanders:
            names.append(String(commander))
        commander_label.text = "Commanders Routed: %s" % ", ".join(names)
    var kills: Dictionary = summary.get("kills", {})
    if kills.is_empty():
        kills_label.text = "Foes Destroyed: None"
    else:
        var kill_lines: Array[String] = []
        for key in kills.keys():
            var label := String(key).capitalize()
            var amount: int = int(kills[key])
            kill_lines.append("%s — %d" % [label, amount])
        kills_label.text = "Foes Destroyed:\n%s" % "\n".join(kill_lines)
    var resources: Dictionary = summary.get("resources", {})
    var metal: int = int(resources.get("metal", 0))
    var essence: int = int(resources.get("essence", 0))
    resources_label.text = "Resources Recovered: Metal %d | Essence %d" % [metal, essence]

func _on_continue_pressed() -> void:
    hide_victory()
    if Engine.has_singleton("GameManager"):
        GameManager.enter_upgrade()
    else:
        var tree := get_tree()
        if tree:
            tree.change_scene_to_file(START_MENU_SCENE_PATH)
