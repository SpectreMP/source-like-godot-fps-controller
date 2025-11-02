extends Label
@export var player:CharacterBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = "Speed: " + str(Vector2(player.velocity.x, player.velocity.z).length()) + "\nHeight: " + str(player.position.y) + "\nCan interact: " + str(player.can_interact)
	pass
