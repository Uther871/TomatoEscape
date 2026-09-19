extends Area2D

@export var heal_amount: int = 1
@export var pickup_delay: float = 0.4

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var collected: bool = false

const PICKUP_SOUND := preload("res://Asety/music/SFX/Misc_01.wav")


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	collision_shape.set_deferred("disabled", true)
	await get_tree().create_timer(pickup_delay).timeout
	if is_instance_valid(self):
		collision_shape.set_deferred("disabled", false)


func _start_launch(from_position: Vector2, to_position: Vector2) -> void:
	global_position = from_position
	_fly_to(to_position)


func _fly_to(target_position: Vector2, duration: float = 0.35, arc_height: float = 24.0) -> void:
	var start_position := global_position
	var tween := create_tween()
	tween.tween_method(
		func(t: float):
			var pos := start_position.lerp(target_position, t)
			pos.y -= arc_height * sin(t * PI)
			global_position = pos,
		0.0, 1.0, duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_body_entered(body: Node2D) -> void:
	if collected:
		return

	if body.is_in_group("player") and body.has_method("heal"):
		collected = true
		body.heal(heal_amount)
		SFX.play(PICKUP_SOUND)
		_play_pickup_effect()


func _play_pickup_effect() -> void:
	collision_shape.set_deferred("disabled", true)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
