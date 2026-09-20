extends Area2D

@export var speed: float = 400.0
var direction: Vector2 = Vector2.RIGHT


func set_direction(dir: Vector2) -> void:
	direction = dir
	rotation = dir.angle()


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(direction)  # direction — вже існуюча змінна напрямку польоту
		queue_free()
	else:
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
