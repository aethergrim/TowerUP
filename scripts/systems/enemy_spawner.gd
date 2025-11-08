extends Node2D

const Constants := preload("res://scripts/constants.gd")

signal wave_started()
signal wave_cleared()
signal enemy_defeated(enemy: Node2D, tier: int, position: Vector2)

@export var grunt_scene: PackedScene = preload("res://scenes/battle/Enemy.tscn")
@export var rusher_scene: PackedScene = preload("res://scenes/battle/Enemy.tscn")
@export var tank_scene: PackedScene = preload("res://scenes/battle/Enemy.tscn")
@export var spawn_delay: float = 1.5
@export var spawn_interval: float = 0.6

var _target: Node2D = null
var _active_enemies: Array[Node2D] = []
@onready var _spawn_markers: Dictionary = {
    Constants.Dir.N: $SpawnN,
    Constants.Dir.E: $SpawnE,
    Constants.Dir.S: $SpawnS,
    Constants.Dir.W: $SpawnW
}
var _pending_spawns: Array[Dictionary] = []
var _delay_timer: float = 0.0
var _spawn_cooldown: float = 0.0
var _remaining_spawn_budget: int = 0
var _spawning_active: bool = false

func set_target(target: Node2D) -> void:
    _target = target

func start_wave(config: Dictionary) -> void:
    cancel_spawning()
    _clear_active_enemies()
    if config.is_empty():
        wave_cleared.emit()
        return
    wave_started.emit()
    var spawn_dirs: Array[int] = []
    var raw_dirs = config.get("spawn_dirs", [])
    for value in raw_dirs:
        spawn_dirs.append(int(value))
    if spawn_dirs.is_empty():
        spawn_dirs = [Constants.Dir.W]
    var count_by_tier: Dictionary = config.get("count_by_tier", {})
    _pending_spawns.clear()
    var total_requests: int = 0
    for tier_key in count_by_tier.keys():
        var count: int = int(count_by_tier[tier_key])
        for index in range(count):
            var dir_index: int = index % spawn_dirs.size()
            var direction: int = int(spawn_dirs[dir_index])
            _pending_spawns.append({
                "tier": int(tier_key),
                "direction": direction
            })
            total_requests += 1
    _remaining_spawn_budget = min(int(config.get("max_enemies", total_requests)), total_requests)
    if _remaining_spawn_budget <= 0 or _pending_spawns.is_empty():
        _pending_spawns.clear()
        if _active_enemies.is_empty():
            wave_cleared.emit()
        set_process(false)
        _spawning_active = false
        return
    _delay_timer = max(spawn_delay, 0.0)
    _spawn_cooldown = 0.0
    _spawning_active = true
    set_process(true)

func _spawn_enemy(tier: int, direction: int) -> void:
    var scene: PackedScene = _get_scene_for_tier(tier)
    if scene == null:
        return
    var enemy := scene.instantiate() as Node2D
    if enemy == null:
        return
    add_child(enemy)
    enemy.global_position = _get_spawn_position(direction)
    if enemy.has_method("initialize"):
        enemy.initialize(_target, tier)
    if enemy.has_signal("died"):
        enemy.died.connect(_on_enemy_died.bind(tier))
    _active_enemies.append(enemy)

func _get_scene_for_tier(tier: int) -> PackedScene:
    match tier:
        Constants.EnemyTier.GRUNT:
            return grunt_scene
        Constants.EnemyTier.RUSHER:
            return rusher_scene
        Constants.EnemyTier.TANK:
            return tank_scene
        _:
            return grunt_scene

func _get_spawn_position(direction: int) -> Vector2:
    if _spawn_markers.has(direction):
        var marker := _spawn_markers[direction] as Marker2D
        if marker:
            return marker.global_position
    var default_marker := _spawn_markers.get(Constants.Dir.W, null) as Marker2D
    if default_marker:
        return default_marker.global_position
    return global_position

func _on_enemy_died(enemy: Node2D, tier: int) -> void:
    var drop_position: Vector2 = enemy.global_position
    _active_enemies.erase(enemy)
    enemy_defeated.emit(enemy, tier, drop_position)
    if _active_enemies.is_empty():
        wave_cleared.emit()

func _clear_active_enemies() -> void:
    for enemy in _active_enemies:
        if is_instance_valid(enemy):
            enemy.queue_free()
    _active_enemies.clear()

func _process(delta: float) -> void:
    if not _spawning_active:
        set_process(false)
        return
    if _delay_timer > 0.0:
        _delay_timer -= delta
        return
    if _spawn_cooldown > 0.0:
        _spawn_cooldown -= delta
        return
    if _remaining_spawn_budget <= 0 or _pending_spawns.is_empty():
        _pending_spawns.clear()
        _spawning_active = false
        set_process(false)
        return
    var spawn_data: Dictionary = _pending_spawns[0]
    _pending_spawns.remove_at(0)
    _spawn_enemy(int(spawn_data.get("tier", Constants.EnemyTier.GRUNT)), int(spawn_data.get("direction", Constants.Dir.W)))
    _remaining_spawn_budget -= 1
    _spawn_cooldown = max(spawn_interval, 0.0)
    if _remaining_spawn_budget <= 0 or _pending_spawns.is_empty():
        _pending_spawns.clear()
        _spawning_active = false
        set_process(false)

func cancel_spawning() -> void:
    _pending_spawns.clear()
    _remaining_spawn_budget = 0
    _delay_timer = 0.0
    _spawn_cooldown = 0.0
    _spawning_active = false
    set_process(false)
