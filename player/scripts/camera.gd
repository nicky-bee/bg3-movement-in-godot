extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 1.0
const DAMPING_FACTOR = 8.0
const ZOOM_SPEED = 200.0
const MIN_ZOOM_DISTANCE = 2.0
const MAX_ZOOM_DISTANCE = 20.0
const ZOOM_DAMPING = 0.9
const RECENTER_SPEED = 10.0
const MOUSE_ROTATION_SPEED = 0.005

@onready var camera_body = $camera_body
@onready var ground_point = self

var zoom_velocity = 0.0
var current_zoom_distance = 10.0
var player: CharacterBody3D
var attached_to_player = true
var rotating_camera = false

func _ready():
	player = get_parent().get_node("%player")
	global_position = player.global_position

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		rotating_camera = event.pressed
	elif event is InputEventMouseMotion and rotating_camera:
		var rotation_delta = event.relative * MOUSE_ROTATION_SPEED
		rotate_camera_around_root(-rotation_delta.y)
		rotate_y(-rotation_delta.x)

	if Input.is_action_just_pressed("recenter"):
		recenter_camera_on_player()

func _physics_process(delta):
	if attached_to_player:
		global_position = global_position.lerp(player.global_position, RECENTER_SPEED * delta)

	camera_body.look_at(global_transform.origin)

	move_in_camera_direction(delta)
	handle_camera_rotation(delta)
	handle_zoom(delta)
	apply_zoom_inertia(delta)
	
	move_and_slide()

func move_in_camera_direction(delta: float):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	if input_dir != Vector2.ZERO:
		attached_to_player = false
		var forward_dir = camera_body.global_transform.basis.z.normalized()
		var right_dir = camera_body.global_transform.basis.x.normalized()
		var move_dir = (forward_dir * input_dir.y + right_dir * input_dir.x).normalized()

		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
		global_transform.origin += velocity * delta
	else:
		apply_damping(delta)

func apply_damping(delta: float):
	velocity.x = move_toward(velocity.x, 0, DAMPING_FACTOR * delta)
	velocity.z = move_toward(velocity.z, 0, DAMPING_FACTOR * delta)

func rotate_camera_around_root(angle: float):
	var to_camera = camera_body.global_transform.origin - ground_point.global_transform.origin
	var rotation = Basis(Vector3.UP, angle)
	to_camera = rotation * to_camera
	camera_body.global_transform.origin = ground_point.global_transform.origin + to_camera

func handle_camera_rotation(delta: float):
	if Input.is_action_pressed("rotate_left"):
		rotate_camera_around_root(-ROTATION_SPEED * delta)
	elif Input.is_action_pressed("rotate_right"):
		rotate_camera_around_root(ROTATION_SPEED * delta)

func handle_zoom(delta: float):
	if Input.is_action_just_released("zoom_in"):
		zoom_velocity -= ZOOM_SPEED * delta
	elif Input.is_action_just_released("zoom_out"):
		zoom_velocity += ZOOM_SPEED * delta

	zoom_velocity = clamp(zoom_velocity, -ZOOM_SPEED, ZOOM_SPEED)

func apply_zoom_inertia(delta: float):
	current_zoom_distance += zoom_velocity * delta
	current_zoom_distance = clamp(current_zoom_distance, MIN_ZOOM_DISTANCE, MAX_ZOOM_DISTANCE)

	var to_camera = (camera_body.global_transform.origin - ground_point.global_transform.origin).normalized()
	camera_body.global_transform.origin = ground_point.global_transform.origin + to_camera * current_zoom_distance

	zoom_velocity *= ZOOM_DAMPING

func recenter_camera_on_player():
	attached_to_player = true
