extends Node2D

const Constants := preload("res://scripts/constants.gd")

signal claimed(loot_type: String)

@export var loot_type: String = Constants.LOOT_METAL
@export var drift_height: float = 8.0
@export var drift_speed: float = 16.0

var _time: float = 0.0
var _base_position: Vector2 = Vector2.ZERO

func _ready() -> void:
    add_to_group("loot")
    set_process(true)
    _base_position = position
    _ensure_placeholder_visual()

func _process(delta: float) -> void:
    _time += delta
    var bob_offset: float = sin(_time * drift_speed) * drift_height
    position = _base_position + Vector2(0, bob_offset)

func claim() -> void:
    claimed.emit(loot_type)
    queue_free()

func _ensure_placeholder_visual() -> void:
    var sprite := get_node_or_null("Sprite2D") as Sprite2D
    if sprite and sprite.texture == null:
        var gradient := GradientTexture2D.new()
        gradient.width = 8
        var grad := Gradient.new()
        grad.colors = PackedColorArray([Color(0.2, 0.8, 0.6), Color(0.0, 0.4, 0.3)])
        gradient.gradient = grad
        sprite.texture = gradient
