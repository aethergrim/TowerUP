extends Node2D

signal loot_collected(loot_id: String)
signal lasso_deployed()
signal lasso_retracted()

@export var max_length: float = 128.0
@export var retract_speed: float = 220.0
@export var deploy_speed: float = 240.0

var _current_length: float = 0.0
var _is_deploying: bool = false
var _origin_position: Vector2 = Vector2.ZERO

func _ready() -> void:
    _origin_position = global_position

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("lasso_action"):
        _start_lasso()
    elif event.is_action_released("lasso_action"):
        _finish_lasso()

func _process(delta: float) -> void:
    if _is_deploying:
        _current_length = clamp(_current_length + deploy_speed * delta, 0.0, max_length)
        if _current_length >= max_length:
            _trigger_collection()
    elif _current_length > 0.0:
        _current_length = max(_current_length - retract_speed * delta, 0.0)
        if _current_length == 0.0:
            lasso_retracted.emit()

func _start_lasso() -> void:
    if _is_deploying:
        return
    _is_deploying = true
    _current_length = 0.0
    _origin_position = global_position
    lasso_deployed.emit()

func _finish_lasso() -> void:
    if not _is_deploying:
        return
    _is_deploying = false
    _trigger_collection()

func _trigger_collection() -> void:
    _is_deploying = false
    _current_length = 0.0
    lasso_retracted.emit()
    loot_collected.emit("generic_resource")
