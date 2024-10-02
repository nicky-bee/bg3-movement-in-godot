extends CharacterBody3D

var camera: CharacterBody3D
var mouse_pos
var speed = 5.0
var marker

@onready var navigation_agent = $navigation_agent

func _ready():
	marker = get_parent().get_parent().get_node("%marker")
	camera = get_parent().get_node("%player_camera")

func _input(event):
	if event is InputEventMouseButton:
		var lmb_pressed = event.button_index == MOUSE_BUTTON_LEFT && event.pressed
		if lmb_pressed:
			var intersect = get_mouse_intersect(event.position)
		
			if intersect:
				mouse_pos = intersect.position
				marker.global_position = mouse_pos
				navigation_agent.set_target_position(mouse_pos)

func _physics_process(delta):
	if navigation_agent.is_target_reached() or navigation_agent.distance_to_target() < 0.01:
		marker.global_position = Vector3(0, -1, 0)
	else:
		var next_point = navigation_agent.get_next_path_position()
		var direction = (next_point - global_transform.origin).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		move_and_slide()

func get_mouse_intersect(mouse_position):
	var current_cam = get_viewport().get_camera_3d()
	var params = PhysicsRayQueryParameters3D.new()
	
	params.from = current_cam.project_ray_origin(mouse_position)
	params.to = current_cam.project_position(mouse_position, 1000)
	
	var worldspace = get_world_3d().direct_space_state
	var result = worldspace.intersect_ray(params)
	
	return result
