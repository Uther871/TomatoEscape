extends CharacterBody2D

@export var speed: float = 90.0
@onready var detection_area: Area2D = $DetectionArea
@onready var catch_area: Area2D = $CatchArea

var target: Node2D = null
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

const ALARM_SOUND := preload("res://Asety/music/SFX/Alarm_01.wav")


func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	catch_area.body_entered.connect(_on_catch_area_body_entered)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if target:
		var direction: float = sign(target.global_position.x - global_position.x)
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

	move_and_slide()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		SFX.play(ALARM_SOUND)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target:
		target = null


func _on_catch_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("get_captured"):
		body.get_captured()
		_freeze_after_catch()


func _freeze_after_catch() -> void:
	set_physics_process(false)
	velocity = Vector2.ZERO
	await get_tree().create_timer(1.0).timeout
	target = null
	set_physics_process(true)
