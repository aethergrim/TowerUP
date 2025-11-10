extends Control

const START_MENU_SCENE_PATH := "res://scenes/main_menu/StartMenu.tscn"

@onready var return_button: Button = $Panel/MarginContainer/VBoxContainer/ReturnButton
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/Title

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    if return_button:
        return_button.pressed.connect(_on_return_pressed)

func show_game_over() -> void:
    visible = true
    _refresh_title()
    if return_button:
        return_button.grab_focus()
    var tree := get_tree()
    if tree:
        tree.paused = true

func hide_game_over() -> void:
    visible = false
    var tree := get_tree()
    if tree:
        tree.paused = false

func _on_return_pressed() -> void:
    var tree := get_tree()
    if tree:
        tree.paused = false
    var manager := _get_game_manager()
    if manager:
        manager.return_to_start_menu()
        return
    var scene: PackedScene = load(START_MENU_SCENE_PATH)
    if scene and tree:
        tree.change_scene_to_packed(scene)

func _refresh_title() -> void:
    if not title_label:
        return
    var day_text: String = ""
    var manager := _get_game_manager()
    if manager:
        var days: int = max(1, manager.days_survived)
        var suffix: String = ""
        if days != 1:
            suffix = "s"
        day_text = "\nThe Tower stood for %d day%s." % [days, suffix]
    title_label.text = "GAME OVER%s" % day_text

func _get_game_manager() -> GameManagerSingleton:
    if Engine.has_singleton("GameManager"):
        return GameManager
    return null
