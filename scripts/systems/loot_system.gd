extends Node2D

signal loot_spawned(loot_id: String, position: Vector2)
signal loot_claimed(loot_id: String)

@export var loot_types: Array[String] = ["metal", "crystal", "essence"]

var active_loot: Array[Dictionary] = []

func spawn_loot(position: Vector2) -> void:
    var loot_id: String = loot_types.pick_random()
    var entry: Dictionary = {
        "id": loot_id,
        "position": position
    }
    active_loot.append(entry)
    loot_spawned.emit(loot_id, position)

func claim_loot(loot_id: String) -> void:
    for i in range(active_loot.size()):
        var entry: Dictionary = active_loot[i]
        if entry["id"] == loot_id:
            active_loot.remove_at(i)
            loot_claimed.emit(loot_id)
            return

func clear_all() -> void:
    active_loot.clear()
