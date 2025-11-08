extends Node

const Constants := preload("res://scripts/constants.gd")

signal wave_started()
signal wave_cleared()
signal enemy_defeated(enemy: Node2D, tier: int, position: Vector2)

@export var grunt_scene: PackedScene = preload("res://scenes/battle/Enemy.tscn")
@export var rusher_scene: PackedScene = preload("res://scenes/battle/Enemy.tscn")
@export var tank_scene: PackedScene = preload("res://scenes/battle/Enemy.tscn")

var _target: Node2D = null
var _active_enemies: Array[Node2D] = []

func set_target(target: Node2D) -> void:
    _target = target

func start_wave(config: Dictionary) -> void:
    _clear_active_enemies()
    if config.is_empty():
        wave_cleared.emit()
        return
    wave_started.emit()
    var spawn_dirs: Array[int] = config.get("spawn_dirs", [])
    if spawn_dirs.is_empty():
        spawn_dirs = [Constants.Dir.W]
    var count_by_tier: Dictionary = config.get("count_by_tier", {})
    for tier_key in count_by_tier.keys():
        var count: int = int(count_by_tier[tier_key])
        for index in range(count):
            var dir_index: int = index % spawn_dirs.size()
            var direction: int = int(spawn_dirs[dir_index])
            _spawn_enemy(tier_key, direction)
    if _active_enemies.is_empty():
        wave_cleared.emit()

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
        enemy.connect("died", Callable(self, "_on_enemy_died").bind(enemy, tier))
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
    var marker_name: String = "SpawnW"
    match direction:
        Constants.Dir.N:
            marker_name = "SpawnN"
        Constants.Dir.E:
            marker_name = "SpawnE"
        Constants.Dir.S:
            marker_name = "SpawnS"
        Constants.Dir.W:
            marker_name = "SpawnW"
        _:
            marker_name = "SpawnW"
    var marker := get_node_or_null(marker_name) as Marker2D
    if marker:
        return marker.global_position
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
