extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var max_size: int = 5
@export var speed_bonus_max: float = 150.0

var current_size: int = max_size
var base_scale: Vector2

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready() -> void:
	add_to_group("player")
	base_scale = scale


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_axis("move_left", "move_right")
	var current_speed := get_current_speed()

	if input_dir != 0:
		velocity.x = move_toward(velocity.x, input_dir * current_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()


func get_current_speed() -> float:
	var size_ratio := float(current_size) / float(max_size)
	return speed + (1.0 - size_ratio) * speed_bonus_max


func take_damage() -> void:
	if current_size > 1:
		current_size -= 1
	update_visual_size()


func update_visual_size() -> void:
	var size_ratio := float(current_size) / float(max_size)
	scale = base_scale * size_ratio


func heal(amount: int = 1) -> void:
	current_size = min(current_size + amount, max_size)
	update_visual_size()
