extends CharacterBody3D

var camera: CharacterBody3D
var mouse_pos
var speed = 5.0
var marker
var inventory_open: bool = false
var on_inventory_ui: bool = false
var target_pickup = null
var pending_drop = null
var world

@export var inventory_data: InventoryData

@onready var navigation_agent = $navigation_agent
@onready var inventory_window: Control = $UI/inventory_window
@onready var pickup_radius: Area3D = $pickup_radius
@onready var mouse_detector: Area3D = $mouse_detector


func _ready():
	world = get_parent()
	marker = get_parent().get_parent().get_node("%marker")
	camera = get_parent().get_node("%player_camera")
	inventory_window.set_player_inventory_data(inventory_data)

func _input(event):
	if event is InputEventMouseButton:
		var lmb_pressed = event.button_index == MOUSE_BUTTON_LEFT && event.pressed
		if lmb_pressed:
			var intersect = get_mouse_intersect(event.position)
		
			if intersect and !inventory_window.grabbed_slot_data:
				if intersect.collider.is_in_group("pickup"):
					handle_pickup_attempt(intersect.collider)
				else:
					mouse_pos = intersect.position
					marker.global_position = mouse_pos
					navigation_agent.set_target_position(mouse_pos)
			elif inventory_window.grabbed_slot_data and !get_on_inventory_ui() and intersect:
				pending_drop = {
					"item_data": inventory_window.grabbed_slot_data,
					"position": intersect.position
				}
				navigation_agent.set_target_position(intersect.position)
				
				if inventory_window.last_grabbed_index != -1:
					inventory_window.last_grabbed_index = -1

	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()

func _physics_process(delta):
	handle_movement()
	handle_proximity_pickup()
	handle_pending_drop()
	handle_mouse_collider()
	
func handle_movement():
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

func toggle_inventory():
	inventory_open = !inventory_open
	inventory_window.window.visible = !inventory_window.window.visible

func get_on_inventory_ui():
	return on_inventory_ui
	
func set_on_inventory_ui(value):
	if value != on_inventory_ui:
		on_inventory_ui = value
		
func get_inventory_open():
	return inventory_open
	
func set_inventory_open(value):
	if value != inventory_open:
		inventory_open = value

func handle_pickup_attempt(item):
	if item in pickup_radius.get_overlapping_bodies():
		pickup_item(item)
	else:
		target_pickup = item
		navigation_agent.set_target_position(item.global_position)

func handle_proximity_pickup():
	if target_pickup and target_pickup in pickup_radius.get_overlapping_bodies():
		pickup_item(target_pickup)
		navigation_agent.target_position = global_position

func pickup_item(item):
	item.set_physics_process(false)
	item.set_process(false)
	
	var tween = get_tree().create_tween()
	var start_pos = item.global_position
	var duration = 0.5
	
	tween.tween_method(
		func(value):
			if is_instance_valid(item) and is_instance_valid(self):
				var end_pos = global_position
				var t = (value - start_pos).length() / (end_pos - start_pos).length()
				var arc_height = sin(t * PI) * 0.5
				item.global_position = value.lerp(end_pos, t) + Vector3(0, arc_height, 0),
		start_pos,
		global_position,
		duration
	)
	
	tween.tween_callback(func():
		if is_instance_valid(item):
			inventory_data.pick_up_slot_data(item.slot_data)
			item.call_deferred("queue_free")
	)

func animate_drop(item, target_position):
	var tween = get_tree().create_tween()
	var start_pos = item.global_position
	var duration = 0.5
	
	tween.tween_method(
		func(value):
			if is_instance_valid(item):
				var t = (value - start_pos).length() / (target_position - start_pos).length()
				var arc_height = sin(t * PI) * 1.5
				item.global_position = value.lerp(target_position, t) + Vector3(0, arc_height, 0),
			start_pos,
			target_position,
			duration
	)
	
	tween.tween_callback(func():
		if is_instance_valid(item):
			item.global_position = target_position
	)

func handle_pending_drop():
	if pending_drop:
		var drop_position = pending_drop["position"]
		
		var collision_shape = pickup_radius.get_child(0) as CollisionShape3D
		if collision_shape and collision_shape.shape is SphereShape3D:
			var radius = collision_shape.shape.radius
			
			if global_position.distance_to(drop_position) <= radius:
				navigation_agent.target_position = global_position
				
				var placed_item = load(pending_drop["item_data"].item_location)
				var instance = placed_item.instantiate()
				world.add_child(instance)
				instance.global_position = global_position
				
				animate_drop(instance, drop_position)
				
				inventory_data.drop_slot_data(pending_drop["item_data"], -1, get_on_inventory_ui())
				
				pending_drop = null

func handle_mouse_collider():
	var intersect = get_mouse_intersect(get_viewport().get_mouse_position())
	
	if intersect:
		mouse_detector.global_position = intersect.position
