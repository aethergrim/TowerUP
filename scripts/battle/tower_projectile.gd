extends Node2D

@export var speed: float = 220.0
@export var damage: float = 8.0
@export var max_lifetime: float = 2.5
@export var hit_radius: float = 10.0

var _target: Node2D = null
var _direction: Vector2 = Vector2.ZERO
var _lifetime: float = 0.0

func initialize(target: Node2D, damage_amount: float) -> void:
    _target = target
    damage = damage_amount
    if is_instance_valid(_target):
        _direction = (_target.global_position - global_position).normalized()
    if _direction == Vector2.ZERO:
        _direction = Vector2.RIGHT
    rotation = _direction.angle()

func _process(delta: float) -> void:
    _lifetime += delta
    if _lifetime >= max_lifetime:
        queue_free()
        return
    if is_instance_valid(_target):
        var to_target: Vector2 = _target.global_position - global_position
        if to_target.length() <= hit_radius + speed * delta:
            _apply_damage(_target)
            return
        _direction = to_target.normalized()
        rotation = _direction.angle()
    if _direction == Vector2.ZERO:
        queue_free()
        return
    global_position += _direction * speed * delta
    _check_proximity_hit()

func _apply_damage(enemy: Node2D) -> void:
    if enemy and enemy.has_method("take_damage"):
        enemy.take_damage(damage)
    queue_free()

func _check_proximity_hit() -> void:
    var enemies: Array = get_tree().get_nodes_in_group("enemies")
    for node in enemies:
        var enemy := node as Node2D
        if enemy == null:
            continue
        if not is_instance_valid(enemy):
            continue
        if enemy.global_position.distance_to(global_position) <= hit_radius:
            _apply_damage(enemy)
            return
