extends Control

@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	if Engine.has_singleton("GameManager"):
		GameManager.start_new_game()

func _on_quit_pressed() -> void:
	get_tree().quit()
