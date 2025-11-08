extends Node2D

@onready var tower: Node = $Tower
@onready var enemy_spawner: Node = $EnemySpawner
@onready var loot_system: Node = $LootSystem
@onready var lasso: Node = $Lasso
@onready var crafting_system: Node = $CraftingSystem
@onready var repair_heat_system: Node = $RepairHeatSystem

var _collected_resources: Dictionary = {
    "metal": 0,
    "crystal": 0,
    "essence": 0
}

func _ready() -> void:
    if Engine.has_singleton("GameManager"):
        enemy_spawner.configure_wave(GameManager.wave_index)
    if tower != null:
        repair_heat_system.register_tower(tower)
    lasso.loot_collected.connect(_on_lasso_loot_collected)
    enemy_spawner.wave_cleared.connect(_on_wave_cleared)
    loot_system.loot_claimed.connect(_on_loot_claimed)
    if Engine.has_singleton("GameManager"):
        GameManager.wave_started.connect(_on_wave_started)

func _process(delta: float) -> void:
    repair_heat_system.perform_cooling(delta * 0.5)

func _on_wave_started(wave_index: int) -> void:
    enemy_spawner.configure_wave(wave_index)
    _reset_resources()

func _on_lasso_loot_collected(loot_id: String) -> void:
    loot_system.claim_loot(loot_id)

func _on_loot_claimed(loot_id: String) -> void:
    if _collected_resources.has(loot_id):
        _collected_resources[loot_id] += 1
    else:
        _collected_resources[loot_id] = 1

func _on_wave_cleared(wave_index: int) -> void:
    var letter_text: String = """Custodian,
Wave %d has fallen silent. Expect resistance in new quarters.
- Opposing General""" % wave_index
    var modifiers: Array[String] = ["Ash Storm", "Magnetic Pulse", "Resource Surge"]
    if Engine.has_singleton("GameManager"):
        GameManager.report_wave_complete(_collected_resources.duplicate(), letter_text, modifiers)

func _reset_resources() -> void:
    for key in _collected_resources.keys():
        _collected_resources[key] = 0
