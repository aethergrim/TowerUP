extends Control

@onready var letter_label: RichTextLabel = $MarginContainer/VBoxContainer/LetterLabel
@onready var modifier_list: ItemList = $MarginContainer/VBoxContainer/ModifierList
@onready var continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton
@onready var letter_system: Control = $LetterSystem

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	modifier_list.item_selected.connect(_on_modifier_selected)
	if letter_system.has_signal("letter_presented"):
		letter_system.letter_presented.connect(_on_letter_presented)
	if letter_system.has_signal("modifier_chosen"):
		letter_system.modifier_chosen.connect(_on_modifier_chosen)
	_populate_letter()

func _populate_letter() -> void:
	var modifiers: Array[String] = []
	var letter_text: String = "Awaiting instructions."
	if Engine.has_singleton("GameManager"):
		letter_text = GameManager.get_letter_text()
		modifiers = GameManager.get_modifiers()
	_on_letter_presented(letter_text)
	modifier_list.clear()
	if modifiers.is_empty():
		modifier_list.add_item("No modifiers this wave")
		modifier_list.set_item_disabled(0, true)
	else:
		for modifier in modifiers:
			modifier_list.add_item(modifier)
	if letter_system.has_method("show_letter"):
		letter_system.call("show_letter", letter_text, modifiers)

func _on_continue_pressed() -> void:
	if Engine.has_singleton("GameManager"):
		GameManager.continue_to_next_wave()

func _on_modifier_selected(index: int) -> void:
	if letter_system.has_method("choose_modifier"):
		letter_system.call("choose_modifier", index)

func _on_letter_presented(text: String) -> void:
	letter_label.text = text

func _on_modifier_chosen(modifier: String) -> void:
	# Placeholder for handling selected modifier effects.
	pass
