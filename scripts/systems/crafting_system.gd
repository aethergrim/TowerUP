extends Node

signal crafting_started(recipe: String)
signal crafting_completed(recipe: String, result: Dictionary)

@export var crafting_time: float = 3.0

var _active_recipe: String = ""
var _timer: float = 0.0
var _is_active: bool = false

func _ready() -> void:
	set_process(true)

func start_crafting(recipe: String) -> void:
	if _is_active:
		return
	_active_recipe = recipe
	_timer = 0.0
	_is_active = true
	crafting_started.emit(recipe)

func _process(delta: float) -> void:
	if not _is_active:
		return
	_timer += delta
	if _timer >= crafting_time:
		_complete_crafting()

func _complete_crafting() -> void:
	_is_active = false
	var result: Dictionary = {
		"recipe": _active_recipe,
		"amount": 5
	}
	crafting_completed.emit(_active_recipe, result)
	_active_recipe = ""
