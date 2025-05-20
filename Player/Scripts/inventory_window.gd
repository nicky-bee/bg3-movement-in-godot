extends Window

@onready var inventory_window: Control = $".."
@onready var inventory: PanelContainer = $inventory

func _ready():
	# Ensure the window is always at least as large as the inventory
	update_min_size()
	inventory.resized.connect(update_min_size)  # Connect to size changes

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("inventory"):
		inventory_window.player.inventory_open = false
		hide()

func update_min_size():
	size = inventory.size  # Prevents shrinking below inventory size
	set_size(size)  # Apply updated size to window
