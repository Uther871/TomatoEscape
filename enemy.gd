extends StaticBody2D

@export var projectile_scene: PackedScene 
@export var shoot_cooldown: float = 1.5    

@onready var shoot_timer: Timer = $ShootTimer
@onready var detection_area: Area2D = $DetectionArea

var player_in_range: bool = false
var target_player: Node2D = null


func _ready() -> void:
	shoot_timer.wait_time = shoot_cooldown
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		target_player = body
		shoot_timer.start()  


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		target_player = null
		shoot_timer.stop()  


func _on_shoot_timer_timeout() -> void:
	if not player_in_range or target_player == null:
		return
	_shoot()


func _shoot() -> void:
	if projectile_scene == null:
		push_warning("Projectile scene не призначена в інспекторі Enemy!")
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)  

	projectile.global_position = global_position
	var direction = (target_player.global_position - global_position).normalized()
	projectile.set_direction(direction)  
