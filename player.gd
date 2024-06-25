extends CharacterBody3D

const MAX_VELOCITY_AIR = 1
const MAX_VELOCITY_GROUND = 6.0
const MAX_ACCELERATION = 15 * MAX_VELOCITY_GROUND

const STOP_SPEED = 1.5

var friction = 4

var SENSITIVITY = 0.002


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity = 9.8

var old_pos = Vector2()

var jumped = false

@onready var head = $Head
@onready var camera = $Head/Camera3D

#@onready var velocity_xz = $CanvasLayer/VBoxContainer/Velocity
#@onready var jump_dist = $CanvasLayer/VBoxContainer/JumpDist
#@onready var pre = $CanvasLayer/VBoxContainer/Pre


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _physics_process(delta):
	var input_dir = Input.get_vector("mleft", "mright", "forward", "backward")
	var wish_dir = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#var wish_dir = input_dir.normalized()
	
	if is_on_floor():
		#if jumped:
			#jump_dist.text = str(snapped(old_pos.distance_to(Vector2(position.x, position.z)), 0.01))
		jumped = false
		
		if Input.is_action_pressed("jump"):
			jumped = true
			#pre.text = str(snapped(Vector2(velocity.x, velocity.z).length(), 0.01))
			old_pos = Vector2(position.x, position.z)
			velocity.y = JUMP_VELOCITY
			
			#velocity = update_velocity_air(wish_dir, delta)
		else:
			velocity = update_velocity_ground(wish_dir, delta)
		
	else:
		velocity.y -= gravity * delta
		velocity = update_velocity_air(wish_dir, delta)
	
	#velocity_xz.text = str(snapped(Vector2(velocity.x, velocity.z).length(), 0.01))
	
	move_and_slide()


func accelerate(wish_dir: Vector3, max_velocity: float, delta):
	# Get our current speed as a projection of velocity onto the wish_dir
	var current_speed = velocity.dot(wish_dir)
	# How much we accelerate is the difference between the max speed and the current speed
	# clamped to be between 0 and MAX_ACCELERATION which is intended to stop you from going too fast
	var add_speed = clamp(max_velocity - current_speed, 0, MAX_ACCELERATION * delta)
	
	return velocity + add_speed * wish_dir

func update_velocity_ground(wish_dir: Vector3, delta):
	# Apply friction when on the ground and then accelerate
	var speed = velocity.length()
	
	if speed != 0:
		var control = max(STOP_SPEED, speed)
		var drop = control * friction * delta
		
		# Scale the velocity based on friction
		velocity *= max(speed - drop, 0) / speed
	
	return accelerate(wish_dir, MAX_VELOCITY_GROUND, delta)
	
func update_velocity_air(wish_dir: Vector3, delta):
	# Do not apply any friction
	return accelerate(wish_dir, MAX_VELOCITY_AIR, delta)
