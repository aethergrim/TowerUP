class_name WaveGen
extends RefCounted

const Constants := preload("res://scripts/constants.gd")
const EnemyTemplates := preload("res://scripts/data/enemy_templates.gd")
const Affixes := preload("res://scripts/data/affixes.gd")

const COMMANDER_NAMES: Array[String] = [
    "Vyr Lask", "General Myrna", "Prophet Kahl", "Admiral Tosk", "Marshal Venne"
]
const INTRO_LINES: Array[String] = [
    "We march again against your blasphemous engine.",
    "This day will see your idol toppled.",
    "The tower's hymn falters; we strike now.",
    "Our banners blot the horizon. Prepare your rites.",
    "We offer no parley—only ruin."
]

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func generate_wave(day: int) -> Array:
    _rng.randomize()
    var directions: Array[int] = _select_directions(day)
    var spec: Array = []
    for dir in directions:
        var template_ids: Array[String] = _select_templates_for_direction(day)
        for template_id in template_ids:
            if template_id == null:
                continue
            var template_data: Dictionary = EnemyTemplates.ENEMY.get(template_id, {})
            if template_data.is_empty():
                continue
            var scaled: Dictionary = scale_stats(template_data, day)
            var affix_lookup = Affixes.FRONT_THEME.get(dir, null)
            var affix_id: String = ""
            if affix_lookup != null:
                affix_id = String(affix_lookup)
            var applied: Dictionary = scaled.duplicate(true)
            if not affix_id.is_empty():
                applied = apply_affix(applied, affix_id)
                applied["affix"] = affix_id
            else:
                applied["affix"] = ""
            applied["template"] = template_id
            applied["dir"] = dir
            applied["count"] = _calculate_count(template_id, day)
            applied["loot"] = _duplicate_loot(template_data.get("loot", {}))
            applied["behavior"] = template_data.get("behavior", "melee_straight")
            applied["vfx"] = applied.get("vfx", null)
            applied["tags"] = _merge_tags(template_data.get("tags", []), applied.get("tags", []))
            spec.append(applied)
    return spec

func build_letter(day: int, spec: Array) -> Dictionary:
    var commander: String = "Unnamed Commander"
    if COMMANDER_NAMES.size() > 0:
        var commander_index: int = _rng.randi_range(0, COMMANDER_NAMES.size() - 1)
        commander = String(COMMANDER_NAMES[commander_index])
    var intro: String = "The enemy advances."
    if INTRO_LINES.size() > 0:
        var intro_index: int = _rng.randi_range(0, INTRO_LINES.size() - 1)
        intro = String(INTRO_LINES[intro_index])
    var summary_lines: Array[String] = []
    var directions: Array[int] = []
    for entry in spec:
        if not (entry is Dictionary):
            continue
        var dir: int = int(entry.get("dir", Constants.Dir.W))
        if not directions.has(dir):
            directions.append(dir)
        var template_id: String = String(entry.get("template", "grunt"))
        var count: int = int(entry.get("count", 1))
        var affix_id: String = String(entry.get("affix", ""))
        var dir_name: String = Constants.get_direction_name(dir)
        var descriptor: String = "%d %s" % [count, template_id.capitalize()]
        if not affix_id.is_empty():
            descriptor += " (%s)" % affix_id
        summary_lines.append("%s front: %s" % [dir_name, descriptor])
    var summary_text: String = "\n".join(summary_lines)
    return {
        "commander": commander,
        "intro": intro,
        "modifier": "",
        "summary": summary_text,
        "directions": directions.duplicate(),
        "wave_index": day + 1
    }

func scale_stats(template: Dictionary, day: int) -> Dictionary:
    var hp: float = float(template.get("base_hp", 10.0)) * (1.0 + 0.12 * float(day))
    var speed: float = float(template.get("base_speed", 40.0)) * (1.0 + 0.02 * float(day))
    var damage: float = float(template.get("base_damage", 5.0)) * (1.0 + 0.08 * float(day))
    return {
        "hp": hp,
        "speed": speed,
        "damage": damage,
        "tags": template.get("tags", []).duplicate()
    }

func apply_affix(base: Dictionary, affix_id: String) -> Dictionary:
    if affix_id == null or affix_id.is_empty():
        return base
    var affix_data: Dictionary = Affixes.AFFIX.get(affix_id, {})
    if affix_data.is_empty():
        return base
    var result: Dictionary = base.duplicate(true)
    result["hp"] = float(result.get("hp", 1.0)) * float(affix_data.get("hp_mult", 1.0))
    result["speed"] = float(result.get("speed", 1.0)) * float(affix_data.get("speed_mult", 1.0))
    result["damage"] = float(result.get("damage", 1.0)) * float(affix_data.get("damage_mult", 1.0))
    if affix_data.has("vfx"):
        result["vfx"] = affix_data["vfx"]
    result["tags"] = _merge_tags(result.get("tags", []), affix_data.get("tags_add", []))
    return result

func _select_directions(day: int) -> Array[int]:
    var available: Array[int] = [Constants.Dir.N, Constants.Dir.E, Constants.Dir.S, Constants.Dir.W]
    available.shuffle()
    var count: int = clamp(1 + int(floor(float(day) / 3.0)), 1, available.size())
    var selection: Array[int] = []
    for index in range(count):
        var value: int = int(available[index])
        selection.append(value)
    return selection

func _select_templates_for_direction(day: int) -> Array[String]:
    var pool: Array[String] = []
    pool.append("grunt")
    if day >= 1:
        pool.append("rusher")
    if day >= 2:
        pool.append("tank")
    if day >= 3:
        pool.append("sapper")
    var count: int = clamp(1 + int(floor(float(day) / 4.0)), 1, pool.size())
    pool.shuffle()
    var selection: Array[String] = []
    for index in range(count):
        var entry = pool[index]
        if entry == null:
            continue
        selection.append(String(entry))
    return selection

func _calculate_count(template_id: String, day: int) -> int:
    var base_count: float = 4.0 + float(day) * 1.5
    match template_id:
        "tank":
            base_count = max(2.0, base_count * 0.5)
        "sapper":
            base_count = max(2.0, base_count * 0.6)
        _:
            pass
    return max(1, int(round(base_count)))

func _duplicate_loot(loot: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for key in loot.keys():
        result[String(key)] = int(loot[key])
    return result

func _merge_tags(base_tags: Array, extra_tags: Array) -> Array:
    var combined: Array[String] = []
    for tag in base_tags:
        var tag_str := String(tag)
        if not combined.has(tag_str):
            combined.append(tag_str)
    for tag in extra_tags:
        var tag_str := String(tag)
        if not combined.has(tag_str):
            combined.append(tag_str)
    return combined
