extends Resource
class_name ItemData

# Functionality
@export var usable: bool = false

# Cosmetic
@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture
@export var texture: Texture
@export var mesh: Mesh

# Inventory
@export var stackable: bool = false
@export var max_stacks: int = 1
@export var sell_price: float = -1.0
@export var buy_price: float = -1.0
