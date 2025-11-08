extends Node

const Constants := preload("res://scripts/constants.gd")

const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"
const UPGRADE_SCENE_PATH := "res://scenes/upgrade/UpgradeScene.tscn"

var current_wave: int = 1
var resources: Dictionary = {
    Constants.LOOT_METAL: 0,
    Constants.LOOT_ESSENCE: 0
}
var current_config: Dictionary = {
    "spawn_dirs": [Constants.Dir.W],
    "count_by_tier": {Constants.EnemyTier.GRUNT: 4},
    "modifier": null
}
var pending_ammo: int = 0
var pending_cooling: float = 0.0
var last_wave_victory: bool = true

func _ready() -> void:
    current_config = _make_wave_config(current_wave)

func start_new_game() -> void:
    current_wave = 1
    resources = {
        Constants.LOOT_METAL: 0,
        Constants.LOOT_ESSENCE: 0
    }
    pending_ammo = 0
    pending_cooling = 0.0
    last_wave_victory = true
    current_config = _make_wave_config(current_wave)
    _change_scene(BATTLE_SCENE_PATH)

func continue_to_next_wave() -> void:
    current_wave += 1
    current_config = _make_wave_config(current_wave)
    _change_scene(BATTLE_SCENE_PATH)

func report_wave_complete(result: Dictionary) -> void:
    var resource_payload: Dictionary = {}
    if result.has("resources") and result["resources"] is Dictionary:
        resource_payload = result["resources"]
    else:
        resource_payload = result
    for key in resource_payload.keys():
        if not resources.has(key):
            resources[key] = 0
        resources[key] += int(resource_payload[key])
    var victory: bool = true
    if result.has("victory"):
        victory = bool(result["victory"])
    last_wave_victory = victory
    _change_scene(UPGRADE_SCENE_PATH)

func get_current_wave_config() -> Dictionary:
    return current_config.duplicate(true)

func get_resources() -> Dictionary:
    return resources.duplicate(true)

func spend_resources(cost: Dictionary) -> bool:
    for key in cost.keys():
        if resources.get(key, 0) < int(cost[key]):
            return false
    for key in cost.keys():
        resources[key] = resources.get(key, 0) - int(cost[key])
    return true

func add_resource(resource_key: String, amount: int) -> void:
    if not resources.has(resource_key):
        resources[resource_key] = 0
    resources[resource_key] += amount

func add_pending_ammo(amount: int) -> void:
    pending_ammo += amount

func consume_pending_ammo() -> int:
    var amount: int = pending_ammo
    pending_ammo = 0
    return amount

func add_pending_cooling(amount: float) -> void:
    pending_cooling += amount

func consume_pending_cooling() -> float:
    var amount: float = pending_cooling
    pending_cooling = 0.0
    return amount

func _make_wave_config(wave: int) -> Dictionary:
    var spawn_dirs: Array[int] = []
    if wave <= 3:
        spawn_dirs = [Constants.Dir.W]
    else:
        spawn_dirs = [Constants.Dir.W, Constants.Dir.N]
    var count_by_tier: Dictionary = {}
    count_by_tier[Constants.EnemyTier.GRUNT] = 4 + wave
    var rusher_count: int = max(0, wave - 3)
    if rusher_count > 0:
        count_by_tier[Constants.EnemyTier.RUSHER] = rusher_count
    count_by_tier[Constants.EnemyTier.TANK] = max(0, wave - 5)
    return {
        "spawn_dirs": spawn_dirs,
        "count_by_tier": count_by_tier,
        "modifier": null
    }

func _change_scene(path: String) -> void:
    var scene: PackedScene = load(path)
    if scene:
        get_tree().change_scene_to_packed(scene)
