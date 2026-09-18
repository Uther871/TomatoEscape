extends StaticBody2D

@export var projectile_scene: PackedScene
@export var gun_rotation_speed: float = 6.0   # чим більше — тим швидше "довертає" ствол до гравця

@onready var gun_pivot: Node2D = $GunPivot
@onready var gun_sprite: Sprite2D = $GunPivot/GunSprite
@onready var hand_sprite: Sprite2D = $GunPivot/HandSprite
@onready var muzzle: Marker2D = $GunPivot/Muzzle
@onready var detection_area: Area2D = $DetectionArea
@onready var shoot_timer: Timer = $ShootTimer

var target: Node2D = null


func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)


func _physics_process(delta: float) -> void:
	if target:
		_aim_at_target(delta)


func _aim_at_target(delta: float) -> void:
	var to_target := target.global_position - gun_pivot.global_position
	var target_angle := to_target.angle()

	# плавний доворот замість миттєвого "клацання" в бік гравця
	gun_pivot.rotation = lerp_angle(gun_pivot.rotation, target_angle, gun_rotation_speed * delta)

	# коли ствол дивиться вліво, перевертаємо спрайти по вертикалі,
	# щоб рука/зброя не опинялись "догори ногами"
	var facing_left: bool = abs(wrapf(gun_pivot.rotation, -PI, PI)) > PI / 2.0
	gun_sprite.flip_v = facing_left
	hand_sprite.flip_v = facing_left


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		shoot_timer.start()


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target:
		target = null
		shoot_timer.stop()


func _on_shoot_timer_timeout() -> void:
	if not target or not projectile_scene:
		return

	var projectile := projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.set_direction(Vector2.RIGHT.rotated(gun_pivot.rotation))
