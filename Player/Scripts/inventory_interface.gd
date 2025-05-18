extends Control

signal drop_slot_data(slot_data: SlotData)

@onready var inventory: PanelContainer = $window/inventory
@onready var window: Window = $window
@onready var mouse_slot: Window = $mouse_slot
@onready var player: CharacterBody3D = $"../.."

@export var drag_margin: int = 10

var dragging := false
var drag_offset := Vector2.ZERO
var last_grabbed_index: int = -1
var item_menu_open = false

var grabbed_slot_data: SlotData
var player_inv_data

func _physics_process(delta: float) -> void:
	if mouse_slot.visible:
		mouse_slot.position = get_global_mouse_position() + Vector2(5, 5)

func set_player_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	inventory.set_inventory_data(inventory_data)
	player_inv_data = inventory_data

func on_inventory_interact(inventory_data: InventoryData, index: int, button: int):
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.grab_slot_data(index)
			last_grabbed_index = index
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index, player.get_on_inventory_ui())
			last_grabbed_index = -1
		[null, MOUSE_BUTTON_RIGHT]:
			if inventory_data.display_slot_data(index) != null:
				open_item_menu(inventory_data.display_slot_data(index))
		[_, MOUSE_BUTTON_RIGHT]:
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
	update_grabbed_slot()
	
func update_grabbed_slot():
	if grabbed_slot_data:
		mouse_slot.show()
		mouse_slot.set_slot_data(grabbed_slot_data)
	else:
		mouse_slot.hide()

func destroy_item_menu():
	for child in window.get_children():
		if child is Control and child.is_in_group("item_menu"):
			child.queue_free()
	item_menu_open = false
	
func open_item_menu(index: SlotData):
	destroy_item_menu()
	item_menu_open = true
	var menu = preload("res://Player/Scenes/item_menu.tscn").instantiate()
	menu.position = window.get_viewport().get_mouse_position()
	window.add_child(menu)
	menu.set_slot_data(index)
	
func is_item_menu_open():
	return item_menu_open

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			drag_offset = get_global_mouse_position() - global_position
			
	elif event is InputEventMouseMotion and dragging:
		global_position - get_global_mouse_position() - drag_offset
		
	if event is InputEventMouseButton \
	and event.is_pressed() \
	and grabbed_slot_data:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				drop_slot_data.emit(grabbed_slot_data)
				grabbed_slot_data = null
		update_grabbed_slot()

func _on_window_mouse_entered() -> void:
	player.set_on_inventory_ui(true)

func _on_window_mouse_exited() -> void:
	player.set_on_inventory_ui(false)

func _on_window_close_requested() -> void:
	player.set_inventory_open(false)
	window.hide()
