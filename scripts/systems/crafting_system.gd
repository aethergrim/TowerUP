extends Node

const Constants := preload("res://scripts/constants.gd")

signal ammo_generated(amount: int)
signal cooling_requested(amount: float)

@export var metal_to_ammo: int = 1
@export var essence_cooling: float = 15.0

func process_loot(loot_type: String) -> void:
    match loot_type:
        Constants.LOOT_METAL:
            ammo_generated.emit(metal_to_ammo)
        Constants.LOOT_ESSENCE:
            cooling_requested.emit(essence_cooling)
        _:
            pass
