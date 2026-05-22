# อัปเดตไฟล์ res://scripts/player_station/furnace_button.gd
extends Interactable

func _ready():
	prompt_message = ""

func interact(player: CharacterBody3D) -> void:
	var mount = get_mount_point()
	if mount:
		var has_block = false
		for child in mount.get_children():
			if child is RigidBody3D:
				has_block = true
				child.queue_free() # ลบวัตถุที่เอามาเผา
		
		if has_block:
			_trigger_fire_effect()

# ดึงฟังก์ชันดั้งเดิมของคุณมาไว้ที่นี่ เพื่อให้เรียกปุ่มเตาหลอมได้ถูกต้อง
func get_mount_point() -> Node3D:
	var main_node = get_parent() # ปรับตามโครงสร้าง Scene จริงของคุณ เพื่อหาจุด Mount
	if main_node and main_node.has_node("MountPoint"):
		return main_node.get_node("MountPoint")
	return null

func _trigger_fire_effect() -> void:
	var main_node = get_parent()
	if main_node and main_node.has_node("FireEffect"):
		var fire = main_node.get_node("FireEffect")
		fire.visible = true
		fire.emitting = true
		await get_tree().create_timer(3.0).timeout
		fire.emitting = false
		await get_tree().create_timer(1.0).timeout
		fire.visible = false

func get_prompt(player: CharacterBody3D) -> String:
	var mount = get_mount_point()
	if mount:
		var has_block = false
		for child in mount.get_children():
			if child is RigidBody3D:
				has_block = true
		if has_block:
			return "Press E to burn"
	return "No block to burn"
