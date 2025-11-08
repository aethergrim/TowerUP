extends Node

signal heat_adjusted(new_heat: float)
signal repaired(new_health: float)

@export var repair_rate: float = 10.0
@export var cooling_rate: float = 15.0

var _tower: Node = null

func register_tower(tower: Node) -> void:
	_tower = tower

func perform_repair(delta: float) -> void:
	if _tower == null:
		return
	if _tower.has_method("repair"):
		_tower.repair(repair_rate * delta)
		repaired.emit(_tower.health)

func perform_cooling(delta: float) -> void:
	if _tower == null:
		return
	if _tower.has_method("cool_by"):
		_tower.cool_by(cooling_rate * delta)
		heat_adjusted.emit(_tower.heat)
