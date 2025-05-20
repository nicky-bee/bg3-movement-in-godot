extends StaticBody3D

@export var slot_data: SlotData

@onready var outline_mesh: MeshInstance3D = $outline_mesh

func show_outline_mesh():
	outline_mesh.show()
	
func hide_outline_mesh():
	outline_mesh.hide()

func _on_detection_area_area_entered(area: Area3D) -> void:
	if area.is_in_group("detector"):
		show_outline_mesh()

func _on_detection_area_area_exited(area: Area3D) -> void:
	if area.is_in_group("detector"):
		hide_outline_mesh()
