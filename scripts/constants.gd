extends RefCounted

enum EnemyTier { GRUNT, RUSHER, TANK }
enum Dir { N, E, S, W }

const LOOT_METAL := "metal"
const LOOT_ESSENCE := "essence"

const DIR_NAMES: Dictionary = {
    Dir.N: "North",
    Dir.E: "East",
    Dir.S: "South",
    Dir.W: "West"
}

const ENEMY_TIER_NAMES: Dictionary = {
    EnemyTier.GRUNT: "Grunt",
    EnemyTier.RUSHER: "Rusher",
    EnemyTier.TANK: "Tank"
}

static func get_direction_name(direction: int) -> String:
    return DIR_NAMES.get(direction, "Unknown")

static func get_enemy_tier_name(tier: int) -> String:
    return ENEMY_TIER_NAMES.get(tier, "Unknown")
