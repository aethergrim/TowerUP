extends Node2D

const Constants := preload("res://scripts/constants.gd")

signal loot_collected(loot_type: String)

enum State { IDLE, DEPLOY, RETRACT }

@export var deploy_duration: float = 0.25
@export var retract_duration: float = 0.25
@export var capture_radius: float = 24.0

var _state: State = State.IDLE
var _progress: float = 0.0
var _origin: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _current_tip: Vector2 = Vector2.ZERO

func _ready() -> void:
    _origin = global_position
    set_process(true)
    set_process_input(true)
    set_process_unhandled_input(true)
    queue_redraw()

func _process(delta: float) -> void:
    match _state:
        State.DEPLOY:
            _progress += delta / max(deploy_duration, 0.001)
            if _progress >= 1.0:
                _progress = 1.0
                _state = State.RETRACT
            _update_tip_position()
        State.RETRACT:
            _progress -= delta / max(retract_duration, 0.001)
            if _progress <= 0.0:
                _progress = 0.0
                _complete_retract()
            _update_tip_position()
        _:
            pass
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("lasso_action"):
        _start_deploy()
    elif event.is_action_released("lasso_action") and _state == State.DEPLOY:
        _state = State.RETRACT

func _start_deploy() -> void:
    if _state != State.IDLE:
        return
    _origin = global_position
    _target = get_global_mouse_position()
    _current_tip = _origin
    _progress = 0.0
    _state = State.DEPLOY

func _complete_retract() -> void:
    _state = State.IDLE
    queue_redraw()
    _capture_loot()

func _update_tip_position() -> void:
    _current_tip = _origin.lerp(_target, _progress)

func _capture_loot() -> void:
    var closest_loot: Node2D = null
    var closest_distance: float = capture_radius
    var loot_nodes: Array = get_tree().get_nodes_in_group("loot")
    for node in loot_nodes:
        var loot := node as Node2D
        if loot == null:
            continue
        var distance: float = loot.global_position.distance_to(_target)
        if distance <= closest_distance:
            closest_loot = loot
            closest_distance = distance
    if closest_loot and closest_loot.has_method("claim"):
        var loot_type: String = Constants.LOOT_METAL
        if closest_loot.has_method("get_loot_type"):
            loot_type = String(closest_loot.get_loot_type())
        else:
            loot_type = String(closest_loot.get("loot_type"))
        closest_loot.claim()
        loot_collected.emit(loot_type)

func _draw() -> void:
    draw_circle(Vector2.ZERO, 6.0, Color(0.95, 0.9, 0.4, 0.35))
    draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 0.8, 0.8))
    if _state == State.IDLE:
        return
    draw_line(to_local(_origin), to_local(_current_tip), Color(0.9, 0.9, 0.5), 2.0)
    draw_circle(to_local(_target), capture_radius, Color(0.8, 0.8, 0.2, 0.15))
