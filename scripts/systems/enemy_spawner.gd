extends Node

signal wave_spawned(wave_index: int, enemies: Array[Dictionary])
signal wave_cleared(wave_index: int)

@export var spawn_directions: Array[String] = ["north", "south", "east", "west"]
@export var base_enemy_count: int = 5

var _active_enemies: Array[Dictionary] = []
var _current_wave: int = 1

func configure_wave(wave_index: int) -> void:
    _current_wave = wave_index
    var total_enemies: int = base_enemy_count + wave_index
    _active_enemies.clear()
    var enemies: Array[Dictionary] = []
    for i in range(total_enemies):
        var entry: Dictionary = {
            "id": "enemy_%s" % i,
            "direction": spawn_directions.pick_random(),
            "tier": _select_tier(wave_index)
        }
        _active_enemies.append(entry)
        enemies.append(entry)
    wave_spawned.emit(wave_index, enemies)

func remove_enemy(enemy_id: String) -> void:
    for i in range(_active_enemies.size()):
        var entry: Dictionary = _active_enemies[i]
        if entry["id"] == enemy_id:
            _active_enemies.remove_at(i)
            break
    if _active_enemies.is_empty():
        wave_cleared.emit(_current_wave)

func _select_tier(wave_index: int) -> String:
    if wave_index < 3:
        return "Grunt"
    if wave_index < 5:
        return "Rusher"
    if wave_index < 7:
        return "Tank"
    if wave_index < 9:
        return "Sapper"
    if wave_index < 11:
        return "Elite"
    return "Swarm"
