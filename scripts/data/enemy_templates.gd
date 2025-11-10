extends RefCounted

const ENEMY: Dictionary = {
    "grunt": {
        "tier": 0,
        "base_hp": 10.0,
        "base_speed": 40.0,
        "base_damage": 5.0,
        "behavior": "melee_straight",
        "loot": {"metal": 1, "essence": 0},
        "tags": ["common"]
    },
    "rusher": {
        "tier": 1,
        "base_hp": 8.0,
        "base_speed": 80.0,
        "base_damage": 6.0,
        "behavior": "melee_straight",
        "loot": {"metal": 1, "essence": 0},
        "tags": ["fast"]
    },
    "tank": {
        "tier": 2,
        "base_hp": 28.0,
        "base_speed": 24.0,
        "base_damage": 10.0,
        "behavior": "melee_straight",
        "loot": {"metal": 2, "essence": 0},
        "tags": ["armored"]
    },
    "sapper": {
        "tier": 2,
        "base_hp": 14.0,
        "base_speed": 36.0,
        "base_damage": 2.0,
        "behavior": "ranged_lob",
        "projectile": {"speed": 220.0, "interval": 2.5, "effect": "acid"},
        "loot": {"metal": 1, "essence": 1},
        "tags": ["ranged", "debuff"]
    }
}
