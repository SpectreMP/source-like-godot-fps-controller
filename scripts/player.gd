extends CharacterBody3D

@onready var head = $Head

@export var mouse_sensitivity = 0.25

@export var ground_walking_speed:float = 2.5 #Gmod - 100 inches
@export var ground_running_speed:float = 5.0 #Gmod - 200 inches
@export var ground_sprinting_speed:float = 10.0 #Gmod - 400 inches
@export var ground_crouching_speed:float = 1.6 #Gmod - 63.3 inches
@export var ground_acceleration:float = 12.0
@export var air_max_speed:float = 1
@export var air_acceleration:float = 20.0
@export var jump_velocity:float = 5.0
@export var frictionAmount:float = 4

@export var stopspeed:float = 1

@export var mass:float = 80
@export var push_multiplier:float = 1.0
@export var crouch_height_multiplier = 0.5
@export var crouch_speed = 0.5


var is_dead:bool= false


func accelerate(wishdir:Vector3, wishspeed:float, accel:float, delta:float) -> void:
	var currentspeed:float
	var addspeed:float
	var accelspeed:float

	if is_dead:
		return

	#See if we are changing direction a bit
	currentspeed = velocity.dot(wishdir)
	
	#Reduce wishspeed by the amount of veer
	addspeed = wishspeed - currentspeed

	#If not going to add any speed, done
	if (addspeed <= 0):
		return

	#Determine amount of acceleration
	accelspeed = accel * delta * wishspeed * frictionAmount

	#Cap at addspeed
	if (accelspeed > addspeed):
		accelspeed = addspeed
	
	#Adjust velocity
	velocity += wishdir * accelspeed


func airAccelerate(wishdir:Vector3, wishspeed:float, accel:float, delta:float) ->void:
	var currentspeed:float
	var addspeed:float
	var accelspeed:float

	if is_dead:
		return
	
	if (wishspeed > 30):
		wishspeed = 30
	
	#Determine veer amount
	currentspeed = velocity.dot(wishdir)

	#See how much to add
	addspeed = wishspeed - currentspeed

	#If not adding any, done
	if (addspeed <= 0):
		return

	#Determine acceleration speed after acceleration
	accelspeed = accel * wishspeed * delta * frictionAmount

	#Cap it
	if (accelspeed > addspeed):
		accelspeed = addspeed
	
	#Adjust velocity
	velocity += wishdir * accelspeed


func friction(delta) -> void:
	var control:float
	var newspeed:float

	var localFriction = frictionAmount
	var speed = velocity.length()

	if (speed < 0.001):
		return

	var drop = 0

	if is_on_floor():
		localFriction *= frictionAmount

		control = max(speed, stopspeed)
		drop += control * localFriction * delta
	
	newspeed = speed - drop
	if (newspeed < 0):
		newspeed = 0

	newspeed /= speed

	velocity *= newspeed

	
func _push_away_rigid_bodies(player_mass:float, force_multiplier:float = 1.0):
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider() is RigidBody3D:
			var push_dir = -collision.get_normal()
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - collision.get_collider().linear_velocity.dot(push_dir)
			velocity_diff_in_push_dir = max(0., velocity_diff_in_push_dir)
			var mass_ratio = min(1.0, player_mass / collision.get_collider().mass)
			push_dir.y = 0
			var push_force = mass_ratio * force_multiplier
			collision.get_collider().apply_impulse(push_dir * velocity_diff_in_push_dir * push_force, collision.get_position() - collision.get_collider().global_position)


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()


	if is_on_floor():
		if Input.is_action_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity
		else:
			friction(delta)
			if Input.is_action_pressed("sprint"):
				accelerate(direction, ground_sprinting_speed, ground_acceleration, delta)
			elif Input.is_action_pressed("walk"):
				accelerate(direction, ground_walking_speed, ground_acceleration, delta)
			else:
				accelerate(direction, ground_running_speed, ground_acceleration, delta)

	else:
		airAccelerate(direction, air_max_speed, air_acceleration, delta)
		velocity += get_gravity() * delta

	if Input.is_action_pressed("menu"):
		get_tree().quit()

	_push_away_rigid_bodies(mass, push_multiplier)
	move_and_slide()
