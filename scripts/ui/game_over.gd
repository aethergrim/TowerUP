extends Control

const START_MENU_SCENE_PATH := "res://scenes/main_menu/StartMenu.tscn"

@onready var return_button: Button = $Panel/MarginContainer/VBoxContainer/ReturnButton

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    if return_button:
        return_button.pressed.connect(_on_return_pressed)

func show_game_over() -> void:
    visible = true
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
    if Engine.has_singleton("GameManager"):
        GameManager.return_to_start_menu()
        return
    var scene: PackedScene = load(START_MENU_SCENE_PATH)
    if scene and tree:
        tree.change_scene_to_packed(scene)
