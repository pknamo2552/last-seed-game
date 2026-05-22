extends Interactable

var has_seed: bool = false
var seed_is_healthy: bool = false

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready():
	prompt_message = "" # ใช้คำนวณ UI Dynamic แบบเดิม

func interact(player: CharacterBody3D) -> void:
	if not player.held_object and has_seed:
		if player.game_manager:
			# พฤติกรรมเดิม: สั่งเริ่มมินิเกมตรวจสอบของโต๊ะ
			player.game_manager.start_station_minigame(self)

func place_action(player: CharacterBody3D) -> void:
	if not has_seed and not player.held_object:
		var seed_index = -1
		for i in range(player.inventory.size()):
			var item = player.inventory[i]
			if item is Dictionary and item.get("label", "") == "Seed":
				seed_index = i
				break
				
		if seed_index >= 0:
			var seed_data = player.inventory[seed_index]
			var is_healthy = seed_data["is_healthy"]
			
			# ดึง LOG ไว้ดีบั๊กตอนวางเมล็ดกลับคืนมาแล้วครับ!
			print("placing seed is_healthy: ", is_healthy)
			
			place_seed(is_healthy)
			player.inventory.remove_at(seed_index)
			player.update_inventory_ui()

func place_seed(is_healthy: bool) -> void:
	has_seed = true
	seed_is_healthy = is_healthy
	var target_color = Color.GREEN if is_healthy else Color.RED
	_change_mesh_color(target_color)

func remove_seed() -> void:
	has_seed = false
	seed_is_healthy = false
	_change_mesh_color(Color.WHITE)

func _change_mesh_color(color: Color) -> void:
	if mesh_instance:
		var new_mat = StandardMaterial3D.new()
		new_mat.albedo_color = color
		mesh_instance.set_surface_override_material(0, new_mat)

func get_prompt(player: CharacterBody3D) -> String:
	if player.held_object:
		return ""
	if has_seed:
		return "Press E to inspect"
	else:
		var has_plain_seed = false
		for item in player.inventory:
			if item is Dictionary and item.get("label", "") == "Seed":
				has_plain_seed = true
				break
		if has_plain_seed:
			return "Press Q to place seed"
		return "No seed to inspect"
