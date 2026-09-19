extends CharacterBody2D

# --- Рух ---
@export var speed: float = 200.0
@export var jump_velocity: float = -320.0        # було -400.0 — стрибок нижчий
@export var acceleration: float = 1500.0
@export var rolling_friction: float = 250.0      # НОВЕ: слабке гальмування = інерція після відпуску
@export var jump_cut_gravity_mult: float = 2.2   # НОВЕ: додаткова гравітація на злеті — коротший, "клацаючий" стрибок

# --- Розмір / "HP" ---
@export var max_size: int = 5
@export var speed_bonus_max: float = 150.0

# --- Кочення ---
@export var roll_radius: float = 16.0  # приблизний радіус томата в px, підбери під спрайт

var current_size: int = max_size
var base_scale: Vector2
var was_on_floor: bool = true

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	base_scale = sprite.scale


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_axis("move_left", "move_right")
	var current_speed := get_current_speed()

	if input_dir != 0:
		# під час утримання клавіші — звичайне керування прискоренням
		velocity.x = move_toward(velocity.x, input_dir * current_speed, acceleration * delta)
	else:
		# після відпуску — слабке гальмування, томат ще трохи котиться за інерцією
		velocity.x = move_toward(velocity.x, 0.0, rolling_friction * delta)

	move_and_slide()

	_update_rolling(delta)
	_check_landing()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	# на злеті (кнопка ще тримається, рух вгору) — звичайна гравітація,
	# при падінні або відпущеній кнопці — посилена, щоб стрибок був коротшим і "клацав" одразу вниз
	if velocity.y < 0.0 and Input.is_action_pressed("jump"):
		velocity.y += gravity * delta
	else:
		velocity.y += gravity * jump_cut_gravity_mult * delta


func _update_rolling(delta: float) -> void:
	if roll_radius > 0.0:
		sprite.rotation += (velocity.x / roll_radius) * delta


func _check_landing() -> void:
	if is_on_floor() and not was_on_floor:
		_play_landing_squash()
	was_on_floor = is_on_floor()


func _play_landing_squash() -> void:
	var target_scale := base_scale_for_size()
	var tween := create_tween()
	sprite.scale = target_scale * Vector2(1.25, 0.75)
	tween.tween_property(sprite, "scale", target_scale, 0.18) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func base_scale_for_size() -> Vector2:
	var size_ratio := float(current_size) / float(max_size)
	return base_scale * size_ratio


func get_current_speed() -> float:
	var size_ratio := float(current_size) / float(max_size)
	return speed + (1.0 - size_ratio) * speed_bonus_max


func take_damage() -> void:
	if current_size > 1:
		current_size -= 1
	update_visual_size()


func update_visual_size() -> void:
	sprite.scale = base_scale_for_size()


func heal(amount: int = 1) -> void:
	current_size = min(current_size + amount, max_size)
	update_visual_size()
