extends Node

const Constants := preload("res://scripts/constants.gd")

const COMMANDERS: Array[Dictionary] = [
    {"name": "General Vorna", "tone": "calculating"},
    {"name": "Marshal Tamsin", "tone": "zealous"},
    {"name": "Admiral Krayne", "tone": "desperate"},
    {"name": "Prophet Lyr", "tone": "deranged"}
]

const MODIFIERS: Array[String] = [
    "Ash Storm clouds the west.",
    "Magnetic Pulse disrupts coolant coils.",
    "Siege Drums quicken enemy resolve.",
    "Saboteurs scatter volatile powder." 
]

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func generate_wave(wave_index: int, last_victory: bool) -> Dictionary:
    _rng.seed = int((wave_index + 1) * 941083) ^ int(last_victory)
    var commander_info: Dictionary = COMMANDERS[(wave_index - 1) % COMMANDERS.size()]
    var spawn_dirs: Array[int] = _select_spawn_dirs(wave_index)
    var tier_counts: Dictionary = _build_tier_counts(wave_index)
    var modifier: String = _pick_modifier(wave_index)
    var intro := _compose_intro(commander_info, wave_index, last_victory)
    var summary := _summarize_wave(spawn_dirs, tier_counts)
    var total_enemies: int = 0
    for value in tier_counts.values():
        total_enemies += int(value)
    return {
        "config": {
            "spawn_dirs": spawn_dirs,
            "count_by_tier": tier_counts,
            "modifier": modifier,
            "max_enemies": total_enemies
        },
        "letter": {
            "commander": commander_info.get("name", "Unknown Commander"),
            "tone": commander_info.get("tone", "grim"),
            "intro": intro,
            "modifier": modifier,
            "summary": summary,
            "directions": spawn_dirs,
            "enemy_counts": tier_counts,
            "wave_index": wave_index
        }
    }

func _select_spawn_dirs(wave_index: int) -> Array[int]:
    var directions: Array[int] = [Constants.Dir.N, Constants.Dir.E, Constants.Dir.S, Constants.Dir.W]
    directions.shuffle()
    var dir_count: int = clamp(1 + int(wave_index / 3.0), 1, directions.size())
    var chosen: Array[int] = []
    for index in range(dir_count):
        chosen.append(int(directions[index]))
    return chosen

func _build_tier_counts(wave_index: int) -> Dictionary:
    var result: Dictionary = {}
    var base_total: int = 5 + wave_index * 2
    var rushers: int = max(0, int(wave_index / 2.0))
    var tanks: int = max(0, int(wave_index / 3.0))
    var grunts: int = max(3, base_total - rushers - tanks)
    result[Constants.EnemyTier.GRUNT] = grunts
    if rushers > 0:
        result[Constants.EnemyTier.RUSHER] = rushers
    if tanks > 0:
        result[Constants.EnemyTier.TANK] = tanks
    return result

func _pick_modifier(wave_index: int) -> String:
    var index: int = wave_index % MODIFIERS.size()
    return MODIFIERS[index]

func _compose_intro(commander_info: Dictionary, wave_index: int, last_victory: bool) -> String:
    var commander_name: String = commander_info.get("name", "Unknown Commander")
    if last_victory:
        return "%s rallies fresh banners for wave %d." % [commander_name, wave_index]
    return "%s senses weakness and presses the assault for wave %d." % [commander_name, wave_index]

func _summarize_wave(spawn_dirs: Array[int], tier_counts: Dictionary) -> String:
    var dir_names: Array[String] = []
    for dir_value in spawn_dirs:
        dir_names.append(Constants.get_direction_name(int(dir_value)))
    var enemy_parts: Array[String] = []
    for tier_key in tier_counts.keys():
        var tier_name := Constants.get_enemy_tier_name(int(tier_key))
        enemy_parts.append("%d %s" % [int(tier_counts[tier_key]), tier_name])
    var directions_text: String = ", ".join(dir_names)
    var enemies_text: String = ", ".join(enemy_parts)
    return "Assault from %s with %s." % [directions_text, enemies_text]
