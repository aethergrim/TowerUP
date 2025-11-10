extends Node2D

const Constants := preload("res://scripts/constants.gd")

signal died(enemy: Node2D, position: Vector2, loot: Dictionary)

@export var speed: float = 40.0
@export var max_health: float = 10.0
@export var contact_damage: float = 4.0
@export var attack_interval: float = 1.2
@export var attack_radius: float = 24.0

var health: float = 0.0
var _target: Node2D = null
var _loot: Dictionary = {}
var _behavior: String = "melee_straight"
var _attack_timer: float = 0.0
var _sprite: Sprite2D = null

func _ready() -> void:
    add_to_group("enemies")
    _sprite = _find_sprite()
    if _sprite and _sprite.texture == null:
        _apply_placeholder_texture()
    if health <= 0.0:
        health = max_health

func initialize(tower: Node2D, spec: Dictionary) -> void:
    _target = tower
    max_health = float(spec.get("hp", max_health))
    speed = float(spec.get("speed", speed))
    contact_damage = float(spec.get("damage", contact_damage))
    _behavior = String(spec.get("behavior", _behavior))
    attack_interval = float(spec.get("attack_interval", attack_interval))
    attack_radius = float(spec.get("attack_radius", attack_radius))
    _loot = spec.get("loot", {}).duplicate(true)
    health = max_health

func take_damage(amount: float) -> void:
    if amount <= 0.0:
        return
    health -= amount
    if health <= 0.0:
        var drop: Dictionary = {}
        for key in _loot.keys():
            drop[String(key)] = int(_loot[key])
        died.emit(self, global_position, drop)
        queue_free()

func _process(delta: float) -> void:
    if _target == null or not is_instance_valid(_target):
        return
    match _behavior:
        "melee_straight":
            _process_melee(delta)
        _:
            _process_melee(delta)

func _process_melee(delta: float) -> void:
    var offset: Vector2 = _target.global_position - global_position
    var distance: float = offset.length()
    if distance > attack_radius:
        var direction: Vector2 = offset.normalized()
        global_position += direction * speed * delta
        _attack_timer = attack_interval
        return
    _attack_timer += delta
    if _attack_timer >= attack_interval:
        _attack_timer = 0.0
        _apply_contact_damage()

func _apply_contact_damage() -> void:
    if _target and _target.has_method("take_damage"):
        _target.take_damage(contact_damage)

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
