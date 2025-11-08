extends Node2D

const Constants := preload("res://scripts/constants.gd")

signal loot_spawned(loot: Node2D)
signal loot_claimed(loot_type: String)

@export var loot_scene: PackedScene = preload("res://scenes/battle/Loot.tscn")

var _active_loot: Array[Node2D] = []

func spawn_loot(spawn_position: Vector2, loot_type: String) -> void:
    if loot_scene == null:
        return
    if loot_type.is_empty():
        loot_type = Constants.LOOT_METAL
    var loot_instance := loot_scene.instantiate() as Node2D
    if loot_instance == null:
        return
    add_child(loot_instance)
    loot_instance.global_position = spawn_position
    if loot_instance.has_variable("loot_type"):
        loot_instance.set("loot_type", loot_type)
    if loot_instance.has_signal("claimed"):
        loot_instance.claimed.connect(_on_loot_claimed)
    _active_loot.append(loot_instance)
    loot_spawned.emit(loot_instance)

func get_loot_nodes() -> Array[Node2D]:
    return _active_loot.duplicate()

func _on_loot_claimed(loot_type: String) -> void:
    var remaining: Array[Node2D] = []
    for loot in _active_loot:
        if is_instance_valid(loot) and not loot.is_queued_for_deletion():
            remaining.append(loot)
    _active_loot = remaining
    loot_claimed.emit(loot_type)
