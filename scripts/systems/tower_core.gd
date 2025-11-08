extends Node2D

signal ammo_consumed(amount: int)
signal overheated()

@warning_ignore("shadowed_global_identifier")
@export var range: float = 120.0
@export var attack_interval: float = 1.0
@export var base_damage: float = 6.0
@export var max_heat: float = 100.0
@export var heat_increase_per_shot: float = 12.0
@export var passive_cool_rate: float = 8.0
@export var ammo: int = 10

var heat: float = 0.0
var _attack_timer: float = 0.0
var _overheat_triggered: bool = false
var _sprite: Sprite2D = null

func _ready() -> void:
    add_to_group("tower")
    set_process(true)
    _sprite = _find_sprite()
    if _sprite and _sprite.texture == null:
        _apply_placeholder_visual()
    queue_redraw()

func _process(delta: float) -> void:
    _attack_timer += delta
    _cool_down(delta)
    if _attack_timer >= attack_interval:
        _attempt_attack()

func _attempt_attack() -> void:
    if ammo <= 0:
        return
    if heat >= max_heat:
        if not _overheat_triggered:
            overheated.emit()
            _overheat_triggered = true
        return
    _attack_timer = 0.0
    ammo -= 1
    ammo_consumed.emit(1)
    heat = min(max_heat, heat + heat_increase_per_shot)
    if heat >= max_heat and not _overheat_triggered:
        overheated.emit()
        _overheat_triggered = true
    _apply_damage_to_enemies()
    queue_redraw()

func _apply_damage_to_enemies() -> void:
    var enemies: Array = get_tree().get_nodes_in_group("enemies")
    for node in enemies:
        var enemy := node as Node2D
        if enemy == null:
            continue
        if enemy.global_position.distance_to(global_position) <= range:
            if enemy.has_method("take_damage"):
                enemy.take_damage(base_damage)

func _cool_down(delta: float) -> void:
    if heat <= 0.0:
        heat = 0.0
        if _overheat_triggered and heat < max_heat:
            _overheat_triggered = false
        return
    heat = max(0.0, heat - passive_cool_rate * delta)
    if heat < max_heat:
        _overheat_triggered = false

func cool_by(amount: float) -> void:
    heat = clamp(heat - amount, 0.0, max_heat)
    if heat < max_heat:
        _overheat_triggered = false

func repair(_percent: float) -> void:
    # Structural repairs are not implemented in the MVP.
    pass

func add_ammo(amount: int) -> void:
    ammo += amount

func _draw() -> void:
    draw_circle(Vector2.ZERO, range, Color(0.7, 0.7, 0.2, 0.2))

func _apply_placeholder_visual() -> void:
    var gradient := GradientTexture2D.new()
    gradient.width = 8
    var grad := Gradient.new()
    grad.colors = PackedColorArray([Color(0.6, 0.7, 0.9), Color(0.2, 0.3, 0.6)])
    gradient.gradient = grad
    _sprite.texture = gradient

func _find_sprite() -> Sprite2D:
    for child in get_children():
        var sprite := child as Sprite2D
        if sprite:
            return sprite
    return null
