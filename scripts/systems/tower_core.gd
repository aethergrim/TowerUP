extends Node2D

signal ammo_consumed(amount: int)
signal overheated()
signal health_changed(current: float, maximum: float)
signal health_depleted()

@export var attack_range: float = 120.0
@export var attack_interval: float = 1.0
@export var base_damage: float = 6.0
@export var max_heat: float = 100.0
@export var heat_increase_per_shot: float = 12.0
@export var passive_cool_rate: float = 8.0
@export var ammo: int = 10
@export var max_health: float = 150.0
@export var projectile_scene: PackedScene = preload("res://scenes/battle/TowerProjectile.tscn")

var heat: float = 0.0
var health: float = 0.0
var _attack_timer: float = 0.0
var _overheat_triggered: bool = false
var _sprite: Sprite2D = null
var _destroyed: bool = false
var _projectile_parent: Node = null

func _ready() -> void:
    add_to_group("tower")
    set_process(true)
    _sprite = _find_sprite()
    if _sprite and _sprite.texture == null:
        _apply_placeholder_visual()
    health = max_health
    _destroyed = false
    health_changed.emit(health, max_health)
    _projectile_parent = get_node_or_null("Projectiles")
    if _projectile_parent == null:
        _projectile_parent = self
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
    var target := _find_target_enemy()
    if target == null:
        return
    _attack_timer = 0.0
    ammo -= 1
    ammo_consumed.emit(1)
    heat = min(max_heat, heat + heat_increase_per_shot)
    if heat >= max_heat and not _overheat_triggered:
        overheated.emit()
        _overheat_triggered = true
    _spawn_projectile(target)
    queue_redraw()
func _find_target_enemy() -> Node2D:
    var enemies: Array = get_tree().get_nodes_in_group("enemies")
    var closest: Node2D = null
    var closest_distance: float = attack_range
    for node in enemies:
        var enemy := node as Node2D
        if enemy == null:
            continue
        if not is_instance_valid(enemy):
            continue
        var distance: float = enemy.global_position.distance_to(global_position)
        if distance > attack_range:
            continue
        if closest == null or distance < closest_distance:
            closest = enemy
            closest_distance = distance
    return closest

func _spawn_projectile(target: Node2D) -> void:
    if projectile_scene == null:
        if target and target.has_method("take_damage"):
            target.take_damage(base_damage)
        return
    var projectile_instance := projectile_scene.instantiate()
    var projectile := projectile_instance as Node2D
    if projectile == null:
        return
    var parent_node: Node = _projectile_parent
    if parent_node == null:
        parent_node = self
    parent_node.add_child(projectile)
    projectile.global_position = global_position
    if projectile.has_method("initialize"):
        projectile.initialize(target, base_damage)

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

func repair(percent: float) -> void:
    if percent <= 0.0:
        return
    var heal_amount: float = max_health * percent
    health = clamp(health + heal_amount, 0.0, max_health)
    if health > 0.0:
        _destroyed = false
    health_changed.emit(health, max_health)

func add_ammo(amount: int) -> void:
    ammo += amount

func _draw() -> void:
    draw_circle(Vector2.ZERO, attack_range, Color(0.7, 0.7, 0.2, 0.2))

func take_damage(amount: float) -> void:
    if amount <= 0.0:
        return
    health = clamp(health - amount, 0.0, max_health)
    health_changed.emit(health, max_health)
    if health <= 0.0 and not _destroyed:
        _destroyed = true
        health_depleted.emit()

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

func apply_upgrade_profile(upgrades: Dictionary) -> void:
    var damage_mult: float = float(upgrades.get("damage_mult", 1.0))
    var heat_mult: float = float(upgrades.get("heat_mult", 1.0))
    var hp_mult: float = float(upgrades.get("hp_mult", 1.0))
    var ammo_mult: float = float(upgrades.get("ammo_mult", 1.0))
    base_damage *= damage_mult
    heat_increase_per_shot *= heat_mult
    max_heat *= 1.0 + (1.0 - heat_mult)
    max_health *= hp_mult
    ammo = int(round(float(ammo) * ammo_mult))
    if ammo < 0:
        ammo = 0
    health = max_health
    health_changed.emit(health, max_health)
