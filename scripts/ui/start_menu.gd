extends Control

signal resolution_changed(new_size: Vector2i)

const AutoloadUtilsConst := preload("res://scripts/utils/autoload_utils.gd")
const GameManagerScript := preload("res://scripts/singletons/GameManager.gd")

# Single source of truth for resolutions:
const RESOLUTION_SIZES: Array[Vector2i] = [
	Vector2i(640, 360),
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
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

	campaign_button.pressed.connect(_start_game)
	quick_button.pressed.connect(_start_game)
	options_button.pressed.connect(func(): options_panel.visible = !options_panel.visible)
	close_options_button.pressed.connect(func(): options_panel.visible = false)
	quit_button.pressed.connect(func(): get_tree().quit())

	volume_slider.value_changed.connect(_on_volume_changed)
	resolution_option.item_selected.connect(_on_resolution_selected)

	_populate_resolutions()
	_sync_volume_slider()
	options_panel.visible = false

# ---------- GAME START ----------
func _start_game() -> void:
	var manager_node := AutoloadUtilsConst.get_autoload("GameManager")
	if manager_node is GameManagerScript:
		var manager: GameManagerSingleton = manager_node as GameManagerSingleton
		manager.start_new_game()
	else:
		push_error("[StartMenu] GameManager autoload missing; unable to start game")

# --- AUDIO ---

func _on_volume_changed(value: float) -> void:
	var db_value: float = -80.0
	if value > 0.001:
		db_value = clamp(linear_to_db(value), -80.0, 0.0)
	AudioServer.set_bus_volume_db(0, db_value)

func _sync_volume_slider() -> void:
	var db_value: float = AudioServer.get_bus_volume_db(0)
	volume_slider.value = 0.0 if db_value <= -80.0 else clamp(db_to_linear(db_value), 0.0, 1.0)

# ---------- RESOLUTION ----------
func _on_resolution_selected(index: int) -> void:
	if index < 0 or index >= RESOLUTION_SIZES.size():
		return
	set_resolution(RESOLUTION_SIZES[index])

func _populate_resolutions() -> void:
	resolution_option.clear()
	for res_size: Vector2i in RESOLUTION_SIZES:
		resolution_option.add_item("%d x %d" % [res_size.x, res_size.y])

	var current: Vector2i = get_resolution()
	var match_index: int = RESOLUTION_SIZES.find(current)
	if match_index == -1:
		match_index = _closest_resolution_index(current)
	resolution_option.select(match_index)

# --- RESOLUTION ---

func _closest_resolution_index(target: Vector2i) -> int:
	var t_area: int = max(1, target.x * target.y)
	var best: int = 0
	var best_delta: int = 2147483647  # big int to start (INT32 max)

	for i in RESOLUTION_SIZES.size():
		var a: int = max(1, RESOLUTION_SIZES[i].x * RESOLUTION_SIZES[i].y)
		var d: int = abs(a - t_area)
		if d < best_delta:
			best_delta = d
			best = i
	return best

# Single write path
func set_resolution(new_size: Vector2i) -> void:
	var window := get_window()
	if window:
		# Order matters: scale target first, then OS size.
		window.content_scale_size = new_size
		window.size = new_size  # routes to DisplayServer internally
		_recenter_window(window)
	else:
		# Early boot / no main window: direct OS call as a fallback.
		DisplayServer.window_set_size(new_size)
		_recenter_window(null)

	emit_signal("resolution_changed", new_size)

# Single read path
func get_resolution() -> Vector2i:
	var window := get_window()
	return window.size if window else DisplayServer.window_get_size()

func _recenter_window(window: Window) -> void:
	if window and window.mode == Window.MODE_WINDOWED:
		window.move_to_center()
		return
	
	var screen := DisplayServer.window_get_current_screen()
	var screen_pos: Vector2i = DisplayServer.screen_get_position(screen)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen)

	var win_size: Vector2i = window.size if window else DisplayServer.window_get_size()
	var pos := screen_pos + (screen_size + win_size) / 2
	DisplayServer.window_set_position(pos)
