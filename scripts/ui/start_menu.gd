extends Control

const RESOLUTION_LABELS: Array[String] = [
    "640 x 360",
    "960 x 540",
    "1280 x 720",
    "1920 x 1080"
]

const RESOLUTION_SIZES: Array[Vector2i] = [
    Vector2i(640, 360),
    Vector2i(960, 540),
    Vector2i(1280, 720),
    Vector2i(1920, 1080)
]

@onready var campaign_button: Button = $MarginContainer/VBoxContainer/CampaignButton
@onready var quick_button: Button = $MarginContainer/VBoxContainer/QuickSkirmishButton
@onready var options_button: Button = $MarginContainer/VBoxContainer/OptionsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton
@onready var options_panel: PanelContainer = $OptionsPanel
@onready var close_options_button: Button = $OptionsPanel/MarginContainer/VBoxContainer/CloseOptionsButton
@onready var volume_slider: HSlider = $OptionsPanel/MarginContainer/VBoxContainer/VolumeRow/VolumeSlider
@onready var resolution_option: OptionButton = $OptionsPanel/MarginContainer/VBoxContainer/ResolutionRow/ResolutionOption

func _ready() -> void:
    if Engine.is_editor_hint():
        ProjectSettings.set_setting("run/window/embedded", false)
    campaign_button.pressed.connect(_on_campaign_pressed)
    quick_button.pressed.connect(_on_quick_pressed)
    options_button.pressed.connect(_on_options_pressed)
    quit_button.pressed.connect(_on_quit_pressed)
    close_options_button.pressed.connect(_on_close_options_pressed)
    volume_slider.value_changed.connect(_on_volume_changed)
    resolution_option.item_selected.connect(_on_resolution_selected)
    _populate_resolutions()
    _sync_volume_slider()
    options_panel.visible = false

func _on_campaign_pressed() -> void:
    var manager := _get_game_manager()
    if manager:
        manager.start_new_game()

func _on_quick_pressed() -> void:
    var manager := _get_game_manager()
    if manager:
        manager.start_new_game()

func _on_options_pressed() -> void:
    options_panel.visible = !options_panel.visible

func _on_close_options_pressed() -> void:
    options_panel.visible = false

func _on_quit_pressed() -> void:
    get_tree().quit()

func _on_volume_changed(value: float) -> void:
    var db_value: float = -80.0
    if value > 0.001:
        db_value = linear_to_db(value)
    AudioServer.set_bus_volume_db(0, clamp(db_value, -80.0, 0.0))

func _on_resolution_selected(index: int) -> void:
    if index < 0 or index >= RESOLUTION_SIZES.size():
        return
    var new_size: Vector2i = RESOLUTION_SIZES[index]
    _apply_resolution(new_size)

func _populate_resolutions() -> void:
    resolution_option.clear()
    for label in RESOLUTION_LABELS:
        resolution_option.add_item(label)
    var current_size: Vector2i = _get_current_window_size()
    var match_index: int = RESOLUTION_SIZES.find(current_size)
    if match_index == -1:
        match_index = 0
    resolution_option.select(match_index)

func _sync_volume_slider() -> void:
    var db_value: float = AudioServer.get_bus_volume_db(0)
    if db_value <= -80.0:
        volume_slider.value = 0.0
    else:
        volume_slider.value = clamp(db_to_linear(db_value), 0.0, 1.0)

func _apply_resolution(new_size: Vector2i) -> void:
    var window := get_window()
    if window:
        window.content_scale_size = new_size
        window.size = new_size
    DisplayServer.window_set_size(new_size)

func _get_current_window_size() -> Vector2i:
    var window := get_window()
    if window:
        return window.size
    return DisplayServer.window_get_size()

func _get_game_manager() -> GameManagerSingleton:
    if Engine.has_singleton("GameManager"):
        return GameManager
    return null
