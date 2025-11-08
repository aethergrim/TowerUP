extends Control

signal letter_presented(text: String)
signal modifier_chosen(modifier: String)

@export_multiline var default_letter: String = """Custodian,
The siege continues. Prepare the tower.
- General Voln"""

var _current_letter: String = ""
var _available_modifiers: Array[String] = []

func show_letter(letter_text: String, modifiers: Array[String]) -> void:
    _current_letter = letter_text if letter_text != "" else default_letter
    _available_modifiers = modifiers.duplicate()
    letter_presented.emit(_current_letter)

func choose_modifier(index: int) -> void:
    if index < 0 or index >= _available_modifiers.size():
        return
    modifier_chosen.emit(_available_modifiers[index])
