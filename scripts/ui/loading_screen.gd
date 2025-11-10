extends Control

const PRELOAD_PATHS: Array[String] = [
    "res://scenes/main_menu/LetterModifierWarning.tscn",
    "res://scenes/battle/BattleScene.tscn",
    "res://scenes/upgrade/UpgradeScene.tscn",
    "res://scenes/battle/Tower.tscn",
    "res://scenes/battle/Enemy.tscn",
    "res://scenes/battle/Loot.tscn"
]

@onready var progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton

var _loading_finished: bool = false

func _ready() -> void:
    progress_bar.value = 0.0
    status_label.text = "Priming divinity..."
    if continue_button:
        continue_button.disabled = true
        continue_button.visible = false
        continue_button.pressed.connect(_on_continue_pressed)
    _begin_loading()

func _begin_loading() -> void:
    var total: int = PRELOAD_PATHS.size()
    if total == 0:
        _loading_complete()
        return
    await _load_paths_async(total)
    _loading_complete()

func _load_paths_async(total: int) -> void:
    var index: int = 0
    for path in PRELOAD_PATHS:
        ResourceLoader.load(path)
        index += 1
        var ratio: float = float(index) / float(total)
        progress_bar.value = ratio * 100.0
        status_label.text = "Preparing assets (%d/%d)" % [index, total]
        await get_tree().process_frame

func _loading_complete() -> void:
    if Engine.has_singleton("GameManager"):
        GameManager.prepare_next_wave()
    _loading_finished = true
    status_label.text = "Siege ready."
    if continue_button:
        continue_button.disabled = false
        continue_button.visible = true
        continue_button.grab_focus()
    else:
        _proceed_to_next_scene()

func _on_continue_pressed() -> void:
    if not _loading_finished:
        return
    _proceed_to_next_scene()

func _proceed_to_next_scene() -> void:
    if Engine.has_singleton("GameManager"):
        GameManager.on_loading_complete()
    else:
        get_tree().change_scene_to_file("res://scenes/main_menu/LetterModifierWarning.tscn")
