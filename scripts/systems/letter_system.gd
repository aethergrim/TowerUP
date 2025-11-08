extends Node

signal letter_updated(text: String)
signal continue_requested()


var _letter_text: String = ""

func _ready() -> void:
    _prepare_letter()

func _prepare_letter() -> void:
    var wave_index: int = 1
    if Engine.has_singleton("GameManager"):
        wave_index = GameManager.current_wave + 1
    _letter_text = "Custodian, wave %d awaits. Hold the tower." % wave_index
    letter_updated.emit(_letter_text)

func get_letter_text() -> String:
    return _letter_text

func confirm() -> void:
    continue_requested.emit()
    if Engine.has_singleton("GameManager"):
        GameManager.continue_to_next_wave()
