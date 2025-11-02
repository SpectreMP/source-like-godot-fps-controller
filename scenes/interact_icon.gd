extends TextureRect

@onready var player = $"../../player"

func _process(delta: float) -> void:
	if player.can_interact:
		show()
	else:
		hide()
