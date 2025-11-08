extends Node2D

signal heat_changed(heat: float)
signal health_changed(health: float)
signal ammo_consumed(amount: int)

@export var max_heat: float = 100.0
@export var heat: float = 0.0
@export var max_health: float = 100.0
@export var health: float = 100.0
@export var ammo: int = 50
@export var heat_cool_rate: float = 5.0
@export var attack_interval: float = 1.5

var _attack_timer: float = 0.0

func _process(delta: float) -> void:
	_attack_timer += delta
	_cool_down(delta)
	if _attack_timer >= attack_interval:
		_attack_timer = 0.0
		_perform_attack()

func _perform_attack() -> void:
	if ammo <= 0:
		return
	ammo -= 1
	heat = clamp(heat + 5.0, 0.0, max_heat)
	ammo_consumed.emit(1)
	heat_changed.emit(heat)

func _cool_down(delta: float) -> void:
	if heat <= 0.0:
		return
	heat = clamp(heat - heat_cool_rate * delta, 0.0, max_heat)
	heat_changed.emit(heat)

func apply_damage(amount: float) -> void:
	health = clamp(health - amount, 0.0, max_health)
	health_changed.emit(health)

func repair(amount: float) -> void:
	health = clamp(health + amount, 0.0, max_health)
	health_changed.emit(health)

func add_ammo(amount: int) -> void:
	ammo += amount

func cool_by(amount: float) -> void:
	heat = clamp(heat - amount, 0.0, max_heat)
	heat_changed.emit(heat)
