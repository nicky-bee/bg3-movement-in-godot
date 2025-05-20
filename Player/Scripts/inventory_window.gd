extends Window

@onready var inventory_window: Control = $".."
@onready var inventory: PanelContainer = $inventory

func _ready() -> void:
	update_min_size()
	inventory.resized.connect(update_min_size)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("inventory"):
		inventory_window.player.set_inventory_open(false)
		hide()

func update_min_size():
	size = inventory.size
	set_size(size)
