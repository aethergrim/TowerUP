extends Node2D

const Constants := preload("res://scripts/constants.gd")

signal died(enemy: Node2D)

@export var speed: float = 40.0
@export var max_health: float = 10.0
@export var contact_damage: float = 2.0
@export var attack_interval: float = 1.2
@export var attack_radius: float = 24.0

var health: float = 0.0
var _target: Node2D = null
var _tier: int = Constants.EnemyTier.GRUNT
var _sprite: Sprite2D = null
var _attack_timer: float = 0.0
var _in_attack_range: bool = false

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
            contact_damage = 6.0
            attack_interval = 1.2
        Constants.EnemyTier.RUSHER:
            speed = 60.0
            max_health = 9.0
            contact_damage = 4.0
            attack_interval = 0.9
        Constants.EnemyTier.TANK:
            speed = 25.0
            max_health = 20.0
            contact_damage = 10.0
            attack_interval = 1.5
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
    var offset: Vector2 = _target.global_position - global_position
    var distance: float = offset.length()
    if distance > attack_radius:
        var direction: Vector2 = offset.normalized()
        global_position += direction * speed * delta
        _in_attack_range = false
        _attack_timer = min(_attack_timer, attack_interval)
    else:
        if not _in_attack_range:
            _in_attack_range = true
            _attack_timer = attack_interval
        _attack_timer += delta
        if _attack_timer >= attack_interval:
            _attack_timer -= attack_interval
            _apply_contact_damage()

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

func _apply_contact_damage() -> void:
    if _target and _target.has_method("take_damage"):
        _target.take_damage(contact_damage)
