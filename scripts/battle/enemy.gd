extends Node2D

const Constants := preload("res://scripts/constants.gd")

signal died(enemy: Node2D)

@export var speed: float = 40.0
@export var max_health: float = 10.0
@export var contact_damage: float = 2.0

var health: float = 0.0
var _target: Node2D = null
var _tier: int = Constants.EnemyTier.GRUNT
var _sprite: Sprite2D = null

func _ready() -> void:
    add_to_group("enemies")
    _sprite = _find_sprite()
    if _sprite and _sprite.texture == null:
        _apply_placeholder_texture()

func initialize(target: Node2D, tier: int) -> void:
    _target = target
    _tier = tier
    match tier:
        Constants.EnemyTier.GRUNT:
            speed = 40.0
            max_health = 12.0
        Constants.EnemyTier.RUSHER:
            speed = 60.0
            max_health = 9.0
        Constants.EnemyTier.TANK:
            speed = 25.0
            max_health = 20.0
        _:
            pass
    health = max_health

func take_damage(amount: float) -> void:
    health -= amount
    if health <= 0.0:
        died.emit(self)
        queue_free()

func _process(delta: float) -> void:
    if _target == null:
        return
    var direction: Vector2 = (_target.global_position - global_position).normalized()
    global_position += direction * speed * delta

func _apply_placeholder_texture() -> void:
    var gradient := GradientTexture2D.new()
    gradient.width = 8
    var grad := Gradient.new()
    grad.colors = PackedColorArray([Color(0.8, 0.2, 0.2), Color(0.4, 0.0, 0.0)])
    gradient.gradient = grad
    _sprite.texture = gradient

func _find_sprite() -> Sprite2D:
    for child in get_children():
        var sprite := child as Sprite2D
        if sprite:
            return sprite
    return null
