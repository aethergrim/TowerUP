extends Node2D

const Constants := preload("res://scripts/constants.gd")

signal wave_started()
signal wave_cleared()
signal enemy_defeated(enemy_position: Vector2, loot: Dictionary, template_id: String)

@export var enemy_scene: PackedScene = preload("res://scenes/battle/Enemy.tscn")
@export var spawn_delay: float = 1.0
@export var spawn_interval: float = 0.75

var _tower: Node2D = null
var _active_enemies: Array[Node2D] = []
var _spawn_queue: Array[Dictionary] = []
var _spawning: bool = false
var _spawn_timer: Timer = null

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
    _spawning = true
    _ensure_spawn_timer()
    _schedule_next_spawn(max(spawn_delay, 0.0))

func _ensure_spawn_timer() -> void:
    if _spawn_timer != null:
        return
    _spawn_timer = Timer.new()
    _spawn_timer.one_shot = true
    _spawn_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
    add_child(_spawn_timer)
    _spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _schedule_next_spawn(delay: float) -> void:
    if _spawn_timer == null:
        return
    _spawn_timer.stop()
    _spawn_timer.wait_time = max(delay, 0.0)
    _spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
    if not _spawning:
        return
    if _spawn_queue.is_empty():
        _spawning = false
        if _active_enemies.is_empty():
            wave_cleared.emit()
        return
    var spec: Dictionary = _spawn_queue[0]
    _spawn_queue.remove_at(0)
    _spawn_enemy(spec)
    if _spawn_queue.is_empty():
        _spawning = false
        if _active_enemies.is_empty():
            wave_cleared.emit()
        return
    _schedule_next_spawn(max(spawn_interval, 0.0))

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
    var template_id: String = String(payload.get("template", "unknown"))
    if enemy_instance.has_method("initialize"):
        enemy_instance.initialize(_tower, payload)
    if enemy_instance.has_signal("died"):
        enemy_instance.died.connect(Callable(self, "_on_enemy_died").bind(template_id))
    _active_enemies.append(enemy_instance)

func _get_spawn_position(direction: int) -> Vector2:
    var marker := _spawn_markers.get(direction, null) as Marker2D
    if marker:
        return marker.global_position
    var fallback := _spawn_markers.get(Constants.Dir.W, null) as Marker2D
    if fallback:
        return fallback.global_position
    return global_position

func _on_enemy_died(enemy: Node2D, death_position: Vector2, loot: Dictionary, template_id: String) -> void:
    _active_enemies.erase(enemy)
    enemy_defeated.emit(death_position, loot, template_id)
    if _active_enemies.is_empty() and _spawn_queue.is_empty():
        wave_cleared.emit()

func cancel_spawning() -> void:
    for enemy in _active_enemies:
        if is_instance_valid(enemy):
            enemy.queue_free()
    _active_enemies.clear()
    _spawn_queue.clear()
    if _spawn_timer:
        _spawn_timer.stop()
    _spawning = false
