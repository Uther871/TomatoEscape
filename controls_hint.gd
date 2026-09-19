extends CanvasLayer

@onready var label: Label = $Label


func _ready() -> void:
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
