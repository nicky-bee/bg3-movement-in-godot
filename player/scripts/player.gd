extends CharacterBody3D

var world
var camera: CharacterBody3D
var mouse_pos
var speed = 5.0
var marker
var inventory_open: bool = false
var target_pickup = null
var on_inventory_ui = false
var pending_drop = null 

@export var inventory_data: InventoryData

@onready var navigation_agent = $navigation_agent
@onready var inventory_interface: Control = $UI/inventory_window
@onready var pickup_radius: Area3D = $pickup_radius

func _ready():
	world = get_parent()
	marker = get_parent().get_parent().get_node("%marker")
	camera = get_parent().get_node("%player_camera")
	inventory_interface.set_player_inventory_data(inventory_data)

func _input(event):
	if event is InputEventMouseButton:
		var lmb_pressed = event.button_index == MOUSE_BUTTON_LEFT && event.pressed
		if lmb_pressed:
			var intersect = get_mouse_intersect(event.position)
			
			# Check if player is trying to drop an item
			if inventory_interface.grabbed_slot_data and !on_inventory_ui and intersect:
				# Store drop details and move player to the location first
				pending_drop = {
					"item_data": inventory_interface.grabbed_slot_data,
					"position": intersect.position
				}
				navigation_agent.set_target_position(intersect.position)
				
				# Reset last grabbed index to prevent repeated drops
				if inventory_interface.last_grabbed_index != -1:
					inventory_interface.last_grabbed_index = -1
		
			# Normal movement and pickup handling if no item is being dropped
			elif intersect and !inventory_interface.grabbed_slot_data:
				if intersect.collider.is_in_group("pickup"):
					handle_pickup_attempt(intersect.collider)
				else:
					mouse_pos = intersect.position
					marker.global_position = mouse_pos
					navigation_agent.set_target_position(mouse_pos)
				
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()

func _physics_process(delta):
	handle_movement()
	handle_proximity_pickup()
	handle_pending_drop()

func handle_movement():
	if navigation_agent.is_target_reached() or navigation_agent.distance_to_target() < 0.01:
		marker.global_position = Vector3(0, -1, 0)
	else:
		var next_point = navigation_agent.get_next_path_position()
		var direction = (next_point - global_transform.origin).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		move_and_slide()

func handle_proximity_pickup():
	if target_pickup and target_pickup in pickup_radius.get_overlapping_bodies():
			pickup_item(target_pickup)
			navigation_agent.target_position = global_position

func handle_pending_drop():
	if pending_drop:
		var drop_position = pending_drop["position"]
		
		# Get the actual radius from the CollisionShape3D inside the pickup_radius
		var collision_shape = pickup_radius.get_child(0) as CollisionShape3D
		if collision_shape and collision_shape.shape is SphereShape3D:
			var radius = collision_shape.shape.radius

			# Stop the player as soon as they reach the radius
			if global_position.distance_to(drop_position) <= radius:
				navigation_agent.target_position = global_position  # Stop movement

				var placed_item = load(pending_drop["item_data"].item_location)
				var instance = placed_item.instantiate()
				world.add_child(instance)
				instance.global_position = global_position  # Start at the player

				# Animate the item moving in an arc
				animate_drop(instance, drop_position)

				# Remove item from inventory
				inventory_data.drop_slot_data(pending_drop["item_data"], -1, get_on_inventory_ui())

				# Clear pending drop
				pending_drop = null

func animate_drop(item, target_position):
	var tween = get_tree().create_tween()
	var start_pos = item.global_position
	var duration = 0.6

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

func get_mouse_intersect(mouse_position):
	if !inventory_open || inventory_interface.grabbed_slot_data:
		var current_cam = get_viewport().get_camera_3d()
		var params = PhysicsRayQueryParameters3D.new()
		
		params.from = current_cam.project_ray_origin(mouse_position)
		params.to = current_cam.project_position(mouse_position, 1000)
		
		var worldspace = get_world_3d().direct_space_state
		var result = worldspace.intersect_ray(params)
		return result
	else:
		return null

func toggle_inventory():
	inventory_open = !inventory_open
	inventory_interface.window.visible = !inventory_interface.window.visible

func handle_pickup_attempt(item: Node3D):
	if item in pickup_radius.get_overlapping_bodies():
		pickup_item(item)
	else:
		target_pickup = item
		navigation_agent.set_target_position(item.global_position)

func pickup_item(item):
	item.set_physics_process(false)  # Disable physics interactions
	item.set_process(false)  # Stop other updates

	var tween = get_tree().create_tween()
	var start_pos = item.global_position
	var duration = 0.5

	tween.tween_method(
		func(value):
			if is_instance_valid(item) and is_instance_valid(self):  # Ensure both exist
				var end_pos = global_position  # Continuously update to player's position
				var t = (value - start_pos).length() / (end_pos - start_pos).length()
				var arc_height = sin(t * PI) * 0.5  # Arc height
				item.global_position = value.lerp(end_pos, t) + Vector3(0, arc_height, 0),
		start_pos,
		global_position,  # This will update dynamically during the tween
		duration
	)

	tween.tween_callback(func():
		if is_instance_valid(item):
			inventory_data.pick_up_slot_data(item.slot_data)
			item.call_deferred("queue_free")  # Defer deletion to prevent errors
	)
	
func get_on_inventory_ui():
	return on_inventory_ui
	
func set_on_inventory_ui(value):
	if value != on_inventory_ui:
		on_inventory_ui = value
