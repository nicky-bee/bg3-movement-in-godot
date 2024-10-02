extends Node3D

@onready var player = %player
@onready var player_camera = %player_camera

func _ready():
	player_camera.global_position = Vector3(player.global_position.x, player.global_position.y + 0.5, player.global_position.z)
