extends Resource
class_name ItemData 

#Looks
@export var name: String = ""   #item name
@export_multiline var description: String = ""   #item description
@export var icon: Texture
@export var texture: Texture
@export var mesh: Mesh

#Inventory
@export var stackable: bool = false   #can the there be more than one of a certain item in a single slot
@export var max_stacks: int = 1   #how many of a certain item can be held in a single slot
@export var sell_price: float = -1.0   #how much the item is sold for, -1 means it can't be sold
@export var buy_price: float = -1.0   #how much the item can be bought for, -1 means it can't be purchased
