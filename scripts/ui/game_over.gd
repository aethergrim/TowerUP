extends Control

const START_MENU_SCENE_PATH := "res://scenes/main_menu/StartMenu.tscn"
const AutoloadUtilsConst := preload("res://scripts/utils/autoload_utils.gd")
const GameManagerScript := preload("res://scripts/singletons/GameManager.gd")

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
    print("[GameOver] RETURN pressed")
    var tree := get_tree()
    if tree:
        tree.paused = false
    var manager_node := AutoloadUtilsConst.get_autoload("GameManager")
    if manager_node is GameManagerScript:
        var manager: GameManagerSingleton = manager_node as GameManagerSingleton
        manager.return_to_start_menu()
        return
    if tree and ResourceLoader.exists(START_MENU_SCENE_PATH):
        var error_code := tree.change_scene_to_file(START_MENU_SCENE_PATH)
        if error_code != OK:
            push_error("[GameOver] Failed to change scene: " + str(error_code))
    else:
        push_error("[GameOver] Missing start menu scene: " + START_MENU_SCENE_PATH)

func _refresh_title() -> void:
    if not title_label:
        return
    var day_text: String = ""
    var manager_node := AutoloadUtilsConst.get_autoload("GameManager")
    if manager_node is GameManagerScript:
        var manager: GameManagerSingleton = manager_node as GameManagerSingleton
        var days: int = max(1, manager.days_survived)
        var suffix: String = ""
        if days != 1:
            suffix = "s"
        day_text = "\nThe Tower stood for %d day%s." % [days, suffix]
    title_label.text = "GAME OVER%s" % day_text
