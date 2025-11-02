extends RigidBody3D
@onready var sound = $AudioStreamPlayer2D

func on_interact():
	sound.play()
