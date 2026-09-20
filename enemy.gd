extends StaticBody2D

@export var projectile_scene: PackedScene
@export var gun_rotation_speed: float = 6.0
@export var sprite_facing_offset: float = PI  # арт намальований "дивиться" вліво за замовчуванням

@onready var gun_pivot: Node2D = $GunPivot
@onready var gun_sprite: Sprite2D = $GunPivot/GunSprite
@onready var hand_sprite: Sprite2D = $GunPivot/HandSprite
@onready var muzzle: Marker2D = $GunPivot/Muzzle
@onready var detection_area: Area2D = $DetectionArea
@onready var shoot_timer: Timer = $ShootTimer

var target: Node2D = null
var current_aim_angle: float = 0.0  # справжній напрямок на гравця, для стрільби

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

	# Дзеркалимо весь GunPivot (а не окремі спрайти flip_v), щоб рука і пістолет
	# завжди лишались синхронізовані, і ніколи не оберталися "через верх" —
	# саме це раніше й перевертало пістолет догори дриґом.
	var facing_right: bool = cos(current_aim_angle) >= 0.0
	var target_rotation: float

	if facing_right:
		gun_pivot.scale.x = -1.0
		target_rotation = current_aim_angle
	else:
		gun_pivot.scale.x = 1.0
		target_rotation = wrapf(current_aim_angle - sprite_facing_offset, -PI, PI)

	gun_pivot.rotation = lerp_angle(gun_pivot.rotation, target_rotation, gun_rotation_speed * delta)


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
	projectile.set_direction(Vector2.RIGHT.rotated(current_aim_angle))  # реальний напрямок, не візуальний
