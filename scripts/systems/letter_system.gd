extends Node

signal letter_updated(text: String)
signal continue_requested()

var _letter_text: String = ""

func _ready() -> void:
    _refresh_letter()

func _refresh_letter() -> void:
    var manager := _get_game_manager()
    if manager:
        var summary: Dictionary = manager.get_letter_summary()
        var commander: String = summary.get("commander", "Unknown Commander")
        var intro: String = summary.get("intro", "The enemy advances.")
        var modifier: String = summary.get("modifier", "")
        var wave_index: int = summary.get("wave_index", manager.days_survived + 1)
        var header: String = "Commander %s" % commander
        var lines: Array[String] = [header, "Wave %d approaches." % wave_index, intro]
        if not modifier.is_empty():
            lines.append(modifier)
        _letter_text = "\n".join(lines)
    else:
        _letter_text = "Orders pending."
    letter_updated.emit(_letter_text)

func get_letter_text() -> String:
    return _letter_text

func confirm() -> void:
    continue_requested.emit()

func _get_game_manager() -> GameManager:
    if Engine.has_singleton("GameManager"):
        return GameManager
    return null
