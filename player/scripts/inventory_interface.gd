extends Control

signal drop_slot_data(slot_data: SlotData)

var grabbed_slot_data: SlotData

@onready var player: CharacterBody3D = $"../.."
@onready var player_inventory: PanelContainer = $window/inventory
@onready var grabbed_slot: Window = $grabbed_slot
@onready var window: Window = $window

@export var drag_margin: int = 10  # How much of the top is draggable

var dragging := false
var drag_offset := Vector2.ZERO
var last_grabbed_index: int = -1

func _physics_process(delta):
	if grabbed_slot.visible:
		grabbed_slot.position = get_global_mouse_position() + Vector2(5, 5)

func set_player_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

func on_inventory_interact(inventory_data: InventoryData,
index: int, button: int) -> void:
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.grab_slot_data(index)
			last_grabbed_index = index
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index, player.get_on_inventory_ui())
			last_grabbed_index = -1
		[null, MOUSE_BUTTON_RIGHT]:
			pass
		[_, MOUSE_BUTTON_RIGHT]:
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
	update_grabbed_slot()

func update_grabbed_slot() -> void:
	if grabbed_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot.hide()
 
func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			drag_offset = get_global_mouse_position() - global_position

	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - drag_offset
		
	if event is InputEventMouseButton \
	and event.is_pressed() \
	and grabbed_slot_data:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				drop_slot_data.emit(grabbed_slot_data)
				grabbed_slot_data = null
			MOUSE_BUTTON_RIGHT:
				drop_slot_data.emit(grabbed_slot_data.create_single_slot_data())
				if grabbed_slot_data.quantity < 1:
					grabbed_slot_data = null
		update_grabbed_slot()

func _on_inventory_mouse_entered() -> void:
	player.set_on_inventory_ui(true)

func _on_inventory_mouse_exited() -> void:
	player.set_on_inventory_ui(false)

func _on_window_close_requested() -> void:
	player.inventory_open = false
	window.hide()
