extends Control

const AutoloadUtils := preload("res://scripts/utils/autoload_utils.gd")

const Constants := preload("res://scripts/constants.gd")

@export var letter_system_path: NodePath

@onready var letter_label: RichTextLabel = $MarginContainer/VBoxContainer/LetterLabel
@onready var resources_label: Label = $MarginContainer/VBoxContainer/ResourcesLabel
@onready var reinforced_button: Button = $MarginContainer/VBoxContainer/ReinforcedButton
@onready var cooling_button: Button = $MarginContainer/VBoxContainer/CoolingButton
@onready var coils_button: Button = $MarginContainer/VBoxContainer/CoilsButton
@onready var storage_button: Button = $MarginContainer/VBoxContainer/StorageButton
@onready var deploy_button: Button = $MarginContainer/VBoxContainer/DeployButton
@onready var abandon_button: Button = $MarginContainer/VBoxContainer/AbandonButton

var _letter_system: Node = null

const UPGRADE_COSTS: Dictionary = {
    "reinforced_hull": {"resource": Constants.LOOT_METAL, "amount": 20},
    "cooling_pipes": {"resource": Constants.LOOT_ESSENCE, "amount": 10},
    "improved_coils": {"resource": Constants.LOOT_METAL, "amount": 15},
    "extra_storage": {"resource": Constants.LOOT_ESSENCE, "amount": 8}
}

func _ready() -> void:
    _letter_system = get_node_or_null(letter_system_path)
    if _letter_system and _letter_system.has_signal("letter_updated"):
        _letter_system.letter_updated.connect(_on_letter_updated)
    if _letter_system and _letter_system.has_method("get_letter_text"):
        _on_letter_updated(_letter_system.get_letter_text())
    reinforced_button.pressed.connect(_on_reinforced_pressed)
    cooling_button.pressed.connect(_on_cooling_pressed)
    coils_button.pressed.connect(_on_coils_pressed)
    storage_button.pressed.connect(_on_storage_pressed)
    deploy_button.pressed.connect(_on_deploy_pressed)
    abandon_button.pressed.connect(_on_abandon_pressed)
    var manager := AutoloadUtils.get_autoload("GameManager") as GameManagerSingleton
    if manager:
        manager.resources_updated.connect(_refresh_resources)
    _refresh_resources()

func _on_letter_updated(text: String) -> void:
    letter_label.text = text

func _refresh_resources() -> void:
    var metal: int = 0
    var essence: int = 0
    var manager := AutoloadUtils.get_autoload("GameManager") as GameManagerSingleton
    if manager:
        var snapshot: Dictionary = manager.get_resources()
        metal = snapshot.get(Constants.LOOT_METAL, 0)
        essence = snapshot.get(Constants.LOOT_ESSENCE, 0)
    resources_label.text = "Metal: %d | Essence: %d" % [metal, essence]

func _attempt_purchase(id: String) -> void:
    var manager := AutoloadUtils.get_autoload("GameManager") as GameManagerSingleton
    if manager == null:
        return
    var cost: Dictionary = UPGRADE_COSTS.get(id, {})
    if cost.is_empty():
        return
    var resource_id: String = cost.get("resource", Constants.LOOT_METAL)
    var amount: int = int(cost.get("amount", 0))
    if manager.spend_resource(resource_id, amount):
        manager.apply_upgrade(id)
        _refresh_resources()

func _on_reinforced_pressed() -> void:
    _attempt_purchase("reinforced_hull")

func _on_cooling_pressed() -> void:
    _attempt_purchase("cooling_pipes")

func _on_coils_pressed() -> void:
    _attempt_purchase("improved_coils")

func _on_storage_pressed() -> void:
    _attempt_purchase("extra_storage")

func _on_deploy_pressed() -> void:
    print("[UpgradeMenu] DEPLOY pressed")
    var manager := AutoloadUtils.get_autoload("GameManager") as GameManagerSingleton
    if manager:
        manager.enter_loading_screen()
    else:
        push_error("[UpgradeMenu] GameManager autoload missing; cannot deploy")
    if _letter_system and _letter_system.has_method("confirm"):
        _letter_system.confirm()

func _on_abandon_pressed() -> void:
    print("[UpgradeMenu] ABANDON pressed")
    var manager := AutoloadUtils.get_autoload("GameManager") as GameManagerSingleton
    if manager:
        manager.return_to_start_menu()
    else:
        push_error("[UpgradeMenu] GameManager autoload missing; cannot abandon")
