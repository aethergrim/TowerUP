extends Control

const Constants := preload("res://scripts/constants.gd")

@export var letter_system_path: NodePath

@onready var letter_label: RichTextLabel = $MarginContainer/VBoxContainer/LetterLabel
@onready var resources_label: Label = $MarginContainer/VBoxContainer/ResourcesLabel
@onready var ammo_button: Button = $MarginContainer/VBoxContainer/AmmoButton
@onready var cool_button: Button = $MarginContainer/VBoxContainer/CoolButton
@onready var continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton

var _letter_system: Node = null

func _ready() -> void:
    _letter_system = get_node_or_null(letter_system_path)
    ammo_button.pressed.connect(_on_ammo_pressed)
    cool_button.pressed.connect(_on_cool_pressed)
    continue_button.pressed.connect(_on_continue_pressed)
    if _letter_system and _letter_system.has_signal("letter_updated"):
        _letter_system.letter_updated.connect(_on_letter_updated)
    if _letter_system and _letter_system.has_method("get_letter_text"):
        _on_letter_updated(_letter_system.get_letter_text())
    _refresh_resources()

func _on_letter_updated(text: String) -> void:
    letter_label.text = text

func _refresh_resources() -> void:
    var display_text: String = "No resources recorded."
    if Engine.has_singleton("GameManager"):
        var values: Dictionary = GameManager.get_resources()
        display_text = "Metal: %d  |  Essence: %d" % [
            values.get(Constants.LOOT_METAL, 0),
            values.get(Constants.LOOT_ESSENCE, 0)
        ]
    resources_label.text = display_text

func _on_ammo_pressed() -> void:
    if not Engine.has_singleton("GameManager"):
        return
    var cost: Dictionary = {Constants.LOOT_METAL: 5}
    if GameManager.spend_resources(cost):
        GameManager.add_pending_ammo(5)
        _refresh_resources()

func _on_cool_pressed() -> void:
    if not Engine.has_singleton("GameManager"):
        return
    var cost: Dictionary = {Constants.LOOT_ESSENCE: 3}
    if GameManager.spend_resources(cost):
        GameManager.add_pending_cooling(30.0)
        _refresh_resources()

func _on_continue_pressed() -> void:
    if _letter_system and _letter_system.has_method("confirm"):
        _letter_system.confirm()
