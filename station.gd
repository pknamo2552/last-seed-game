extends StaticBody3D

var has_seed: bool = false
var seed_is_healthy: bool = false
var game_manager = null

func _ready():
	game_manager = get_tree().get_first_node_in_group("game_manager")

func place_seed(is_healthy: bool):
	has_seed = true
	seed_is_healthy = is_healthy
	var mesh = $MeshInstance3D
	var new_mat = StandardMaterial3D.new()
	new_mat.albedo_color = Color.GREEN
	mesh.set_surface_override_material(0, new_mat)

func remove_seed():
	has_seed = false
	var mesh = $MeshInstance3D
	var new_mat = StandardMaterial3D.new()
	new_mat.albedo_color = Color.WHITE
	mesh.set_surface_override_material(0, new_mat)

func inspect():
	if not has_seed:
		game_manager.show_result("ไม่มีเมล็ดในถาด")
		return
	game_manager.start_station_minigame(self)
