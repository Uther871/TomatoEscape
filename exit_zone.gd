extends Area2D

signal player_escaped

@export var win_scene_path: String = ""  # шлях до сцени перемоги; лиши порожнім, щоб просто заморозити гру

var triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	if body.is_in_group("player"):
		triggered = true
		player_escaped.emit()
		_handle_win(body)


func _handle_win(player: Node2D) -> void:
	# Мінімальна win-логіка без окремої сцени: зупиняємо гравця й показуємо напис.
	if player.has_method("set_physics_process"):
		player.set_physics_process(false)
	player.velocity = Vector2.ZERO

	if win_scene_path != "":
		get_tree().change_scene_to_file(win_scene_path)
		return

	_show_fallback_label()


func _show_fallback_label() -> void:
	var label := Label.new()
	label.text = "ВТІК! 🍅"
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)

	var layer := CanvasLayer.new()
	layer.add_child(label)
	get_tree().current_scene.add_child(layer)
