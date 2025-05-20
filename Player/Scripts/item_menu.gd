extends Window

var index: SlotData
var parent

@onready var split_menu: Window = $split_menu_window
@onready var quantity_label: Label = $split_menu_window/split_menu/item_container/quantity_label
@onready var quantity_slider: HSlider = $split_menu_window/split_menu/item_container/quantity_slider

func _ready() -> void:
	parent = get_parent().get_parent()
	position = parent.get_global_mouse_position()

func set_slot_data(slot_data):
	index = slot_data

func _on_use_button_button_up() -> void:
	print("Used the ", index.item_data.name)

func _on_split_button_button_up() -> void:
	if parent.is_item_menu_open() and index.quantity > 1:
		quantity_slider.max_value = index.quantity - 1
		quantity_slider.value = index.quantity / 2
		split_menu.position = position
		split_menu.show()

func _on_quantity_slider_value_changed(value: float) -> void:
	quantity_label.text = str(quantity_slider.value)

func _on_split_confirm_button_button_up() -> void:
	index.quantity = index.quantity - quantity_slider.value
	parent.player_inv_data.place_item_quantity(index, quantity_slider.value)
	split_menu.hide()
	queue_free()
