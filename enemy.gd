extends StaticBody2D

@export var projectile_scene: PackedScene
@export var gun_rotation_speed: float = 6.0
@export var sprite_facing_offset: float = PI  
@onready var gun_pivot: Node2D = $GunPivot
@onready var gun_sprite: Sprite2D = $GunPivot/GunSprite
@onready var hand_sprite: Sprite2D = $GunPivot/HandSprite
@onready var muzzle: Marker2D = $GunPivot/Muzzle
@onready var detection_area: Area2D = $DetectionArea
@onready var shoot_timer: Timer = $ShootTimer

var target: Node2D = null
var current_aim_angle: float = 0.0  

const ATTACK_SOUNDS := [
	preload("res://Asety/music/SFX/Attack_01.wav"),
	preload("res://Asety/music/SFX/Attack_02.wav"),
	preload("res://Asety/music/SFX/Atttack_03.wav"),
]
const ALARM_SOUND := preload("res://Asety/music/SFX/Alarm_01.wav")


func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)


func _physics_process(delta: float) -> void:
	if target:
		_aim_at_target(delta)


func _aim_at_target(delta: float) -> void:
	var to_target := target.global_position - gun_pivot.global_position
	current_aim_angle = to_target.angle()

	var visual_angle := current_aim_angle + sprite_facing_offset
	gun_pivot.rotation = lerp_angle(gun_pivot.rotation, visual_angle, gun_rotation_speed * delta)

	var facing_left: bool = abs(wrapf(current_aim_angle, -PI, PI)) > PI / 2.0
	gun_sprite.flip_v = facing_left
	hand_sprite.flip_v = facing_left


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		shoot_timer.start()
		SFX.play(ALARM_SOUND)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
		shoot_timer.stop()


func _on_shoot_timer_timeout() -> void:
	if not target or not projectile_scene:
		return

	SFX.play_random(ATTACK_SOUNDS)
	var projectile := projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.set_direction(Vector2.RIGHT.rotated(current_aim_angle))  
