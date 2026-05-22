extends Interactable

func _ready():
	prompt_message = "" # ใช้คำนวณตามเงื่อนไขไอเทมที่ถือ

func dig_action(player: CharacterBody3D) -> void:
	# ตรวจเงื่อนไขกระเป๋าและอุปกรณ์เหมือนเดิมเป๊ะๆ
	if player.held_object and player.held_object.is_in_group("shovel"):
		if player.inventory.size() < player.max_inventory:
			randomize()
			var is_healthy = randi() % 10 < 4
			
			# ดึง LOG ไว้ดีบั๊กตอนขุดเมล็ดขึ้นมากลับคืนมาแล้วครับ!
			print("dug seed is_healthy: ", is_healthy)
			
			player.inventory.append({"type": "seed", "is_healthy": is_healthy, "label": "Seed"})
			player.update_inventory_ui()
			get_parent().queue_free() # ทำลายวัตถุดินชิ้นนี้ทิ้ง (เดิมสั่ง target.queue_free())

func get_prompt(player: CharacterBody3D) -> String:
	if player.held_object and player.held_object.is_in_group("shovel"):
		return "Press F to dig"
	elif not player.held_object:
		return "ถือพลั่วก่อน!"
	return ""
