extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -300.0
@export var acceleration: float = 1500.0
@export var rolling_friction: float = 250.0
@export var jump_cut_gravity_mult: float = 2.2
@export var landing_impact_threshold: float = 100.0
@export var max_size: int = 5
@export var speed_bonus_max: float = 150.0
@export var roll_radius: float = 16.0
@export var collectible_scene: PackedScene
@export var scatter_radius: float = 20.0

var current_size: int = max_size
var base_scale: Vector2
var base_collision_scale: Vector2
var was_on_floor: bool = true
var fall_velocity: float = 0.0
var is_stunned: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var landing_particles: GPUParticles2D = $LandingParticles
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var camera: Camera2D = get_node_or_null("Camera2D")

var spawn_position: Vector2

const HURT_SOUNDS := [
	preload("res://Asety/music/SFX/Hurt_01.wav"),
	preload("res://Asety/music/SFX/Hurt_02.wav"),
	preload("res://Asety/music/SFX/Hurt_03.wav"),
	preload("res://Asety/music/SFX/Hurt_04.wav"),
]
const CAPTURE_SOUND := preload("res://Asety/music/SFX/Death_01.wav")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()


func _ready() -> void:
	add_to_group("player")
	base_scale = sprite.scale
	base_collision_scale = collision_shape.scale
	spawn_position = global_position
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	if not is_on_floor():
		fall_velocity = velocity.y

	if is_stunned:
		move_and_slide()
		_update_rolling(delta)
		_check_landing()
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_axis("move_left", "move_right")
	var current_speed := get_current_speed()

	if input_dir != 0:
		velocity.x = move_toward(velocity.x, input_dir * current_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, rolling_friction * delta)

	move_and_slide()

	_update_rolling(delta)
	_check_landing()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	if velocity.y < 0.0 and Input.is_action_pressed("jump"):
		velocity.y += gravity * delta
	else:
		velocity.y += gravity * jump_cut_gravity_mult * delta


func _update_rolling(delta: float) -> void:
	if roll_radius > 0.0:
		sprite.rotation += (velocity.x / roll_radius) * delta


func _check_landing() -> void:
	if is_on_floor() and not was_on_floor:
		if fall_velocity > landing_impact_threshold:
			_play_landing_squash()
			landing_particles.restart()
		fall_velocity = 0.0
	was_on_floor = is_on_floor()


func _play_landing_squash() -> void:
	var target_scale := base_scale_for_size()
	var tween := create_tween()
	sprite.scale = target_scale * Vector2(1.25, 0.75)
	tween.tween_property(sprite, "scale", target_scale, 0.18) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func size_ratio() -> float:
	return float(current_size) / float(max_size)


func base_scale_for_size() -> Vector2:
	return base_scale * size_ratio()


func get_current_speed() -> float:
	return speed + (1.0 - size_ratio()) * speed_bonus_max


func take_damage(knockback_dir: Vector2 = Vector2.ZERO, knockback_force: float = 350.0) -> void:
	if current_size > 1:
		current_size -= 1
	_spawn_scattered_piece()
	update_visual_size()
	hit_particles.restart()
	_shake_camera(4.0, 0.2)
	SFX.play_random(HURT_SOUNDS)

	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir.normalized() * knockback_force
		velocity.y -= 120  
		_start_stun(0.25)


func _start_stun(duration: float) -> void:
	is_stunned = true
	await get_tree().create_timer(duration).timeout
	is_stunned = false


func get_captured() -> void:
	set_physics_process(false)
	_shake_camera(6.0, 0.3)
	SFX.play(CAPTURE_SOUND)
	await get_tree().create_timer(1.0).timeout
	_respawn()


func _respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	current_size = max_size
	update_visual_size()
	set_physics_process(true)


func _shake_camera(strength: float, duration: float) -> void:
	if not camera:
		return

	var tween := create_tween()
	var steps := 6
	for i in steps:
		var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(camera, "offset", offset, duration / steps)
	tween.tween_property(camera, "offset", Vector2.ZERO, duration / steps)


func _spawn_scattered_piece() -> void:
	if not collectible_scene:
		return

	var piece := collectible_scene.instantiate()
	var offset := Vector2(randf_range(-scatter_radius, scatter_radius), -randf_range(10.0, scatter_radius))
	var piece_spawn_position := global_position
	var target_position := global_position + offset

	get_tree().current_scene.add_child.call_deferred(piece)
	piece.call_deferred("_start_launch", piece_spawn_position, target_position)


func update_visual_size() -> void:
	sprite.scale = base_scale_for_size()
	collision_shape.scale = base_collision_scale * size_ratio()


func heal(amount: int = 1) -> void:
	current_size = min(current_size + amount, max_size)
	update_visual_size()
