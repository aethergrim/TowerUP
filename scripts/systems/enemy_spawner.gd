extends Node2D

const Constants := preload("res://scripts/constants.gd")

signal wave_started()
signal wave_cleared()
signal enemy_defeated(position: Vector2, loot: Dictionary)

@export var enemy_scene: PackedScene = preload("res://scenes/battle/Enemy.tscn")
@export var spawn_delay: float = 1.0
@export var spawn_interval: float = 0.75

var _tower: Node2D = null
var _active_enemies: Array[Node2D] = []
var _spawn_queue: Array[Dictionary] = []
var _delay_timer: float = 0.0
var _interval_timer: float = 0.0
var _spawning: bool = false
var _enemy_specs: Dictionary = {}

@onready var _spawn_markers: Dictionary = {
    Constants.Dir.N: $SpawnN,
    Constants.Dir.E: $SpawnE,
    Constants.Dir.S: $SpawnS,
    Constants.Dir.W: $SpawnW
}

func start_wave(wave_spec: Array, tower_ref: Node2D) -> void:
    cancel_spawning()
    _tower = tower_ref
    _spawn_queue = []
    for entry in wave_spec:
        if not (entry is Dictionary):
            continue
        var count: int = int(entry.get("count", 0))
        for _i in range(count):
            _spawn_queue.append(entry.duplicate(true))
    if _spawn_queue.is_empty():
        wave_cleared.emit()
        return
    wave_started.emit()
    _delay_timer = max(spawn_delay, 0.0)
    _interval_timer = 0.0
    _spawning = true
    set_process(true)

func _process(delta: float) -> void:
    if not _spawning:
        set_process(false)
        return
    if _delay_timer > 0.0:
        _delay_timer -= delta
        return
    if _interval_timer > 0.0:
        _interval_timer -= delta
        return
    if _spawn_queue.is_empty():
        _spawning = false
        if _active_enemies.is_empty():
            wave_cleared.emit()
        set_process(false)
        return
    var spec: Dictionary = _spawn_queue.pop_front()
    _spawn_enemy(spec)
    _interval_timer = max(spawn_interval, 0.0)

func _spawn_enemy(spec: Dictionary) -> void:
    if enemy_scene == null:
        return
    var enemy_instance := enemy_scene.instantiate() as Node2D
    if enemy_instance == null:
        return
    add_child(enemy_instance)
    var direction: int = int(spec.get("dir", Constants.Dir.W))
    enemy_instance.global_position = _get_spawn_position(direction)
    var payload: Dictionary = spec.duplicate(true)
    if enemy_instance.has_method("initialize"):
        enemy_instance.initialize(_tower, payload)
    if enemy_instance.has_signal("died"):
        enemy_instance.died.connect(_on_enemy_died)
    _active_enemies.append(enemy_instance)
    _enemy_specs[enemy_instance] = spec

func _get_spawn_position(direction: int) -> Vector2:
    var marker := _spawn_markers.get(direction, null) as Marker2D
    if marker:
        return marker.global_position
    var fallback := _spawn_markers.get(Constants.Dir.W, null) as Marker2D
    if fallback:
        return fallback.global_position
    return global_position

func _on_enemy_died(enemy: Node2D, position: Vector2, loot: Dictionary) -> void:
    _active_enemies.erase(enemy)
    _enemy_specs.erase(enemy)
    enemy_defeated.emit(position, loot)
    if _active_enemies.is_empty() and _spawn_queue.is_empty():
        wave_cleared.emit()

func cancel_spawning() -> void:
    for enemy in _active_enemies:
        if is_instance_valid(enemy):
            enemy.queue_free()
    _active_enemies.clear()
    _spawn_queue.clear()
    _enemy_specs.clear()
    _delay_timer = 0.0
    _interval_timer = 0.0
    _spawning = false
    set_process(false)
