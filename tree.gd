extends Node3D
@onready var leaves: MeshInstance3D = $leaves

func _ready() -> void:
		scale = scale * randf_range(0.8,1.2)
		var a : Color 
		rotation_degrees.y += randi_range(0,90)
		var possible_colors :Array[Color] = [Color(0.6,0.9,0.4),Color(0.61,0.9,0.4),Color(0.62,0.9,0.4),Color(0.63,0.9,0.4),Color(0.64,0.9,0.4),Color(0.65,0.9,0.4),Color(0.66,0.9,0.4),Color(0.67,0.9,0.4),Color(0.68,0.9,0.4)]
		leaves.mesh.surface_get_material(0).set("albedo_color",possible_colors.pick_random())

		
		
		
