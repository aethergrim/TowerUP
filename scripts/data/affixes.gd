extends RefCounted

const Constants := preload("res://scripts/constants.gd")

const AFFIX: Dictionary = {
    "Frostbitten": {
        "hp_mult": 1.0,
        "speed_mult": 0.9,
        "damage_mult": 1.0,
        "vfx": "ice_aura",
        "tags_add": ["cold"]
    },
    "Enraged": {
        "hp_mult": 1.0,
        "speed_mult": 1.2,
        "damage_mult": 1.25,
        "vfx": "rage_aura",
        "tags_add": ["berserk"]
    },
    "Shielded": {
        "hp_mult": 1.3,
        "speed_mult": 0.95,
        "damage_mult": 1.0,
        "vfx": "shield_aura",
        "tags_add": ["armored"]
    }
}

const FRONT_THEME: Dictionary = {
    Constants.Dir.N: "Frostbitten",
    Constants.Dir.S: "Enraged",
    Constants.Dir.E: "Shielded",
    Constants.Dir.W: null
}
