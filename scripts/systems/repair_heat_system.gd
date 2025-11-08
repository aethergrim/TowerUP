extends Node

@export var cooling_amount: float = 25.0
@export var repair_percent: float = 0.1

var _tower: Node = null

func _ready() -> void:
    set_process_unhandled_input(true)

func register_tower(tower: Node) -> void:
    _tower = tower

func perform_cooling() -> void:
    if _tower == null:
        return
    if _tower.has_method("cool_by"):
        _tower.cool_by(cooling_amount)

func perform_repair() -> void:
    if _tower == null:
        return
    if _tower.has_method("repair"):
        _tower.repair(repair_percent)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("cool_action"):
        perform_cooling()
    elif event.is_action_pressed("repair_action"):
        perform_repair()
