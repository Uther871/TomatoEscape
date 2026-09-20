extends Node

# Глобальний автозавантажуваний синглтон для SFX.
# Виклик: SFX.play(preload("res://Asety/music/SFX/Hurt_01.wav"))


func play(stream: AudioStream, volume_db: float = -22.0) -> void:
	if not stream:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func play_random(streams: Array, volume_db: float = -22.0) -> void:
	if streams.is_empty():
		return
	play(streams[randi() % streams.size()], volume_db)
