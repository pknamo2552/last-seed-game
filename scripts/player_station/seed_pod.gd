extends Interactable

var is_healthy: bool = true

func _ready():
	prompt_message = "Press E to collect seed"
	reset()

func interact(player: CharacterBody3D) -> void:
	if player.game_manager:
		player.game_manager.start_seed_minigame(self)

func reset() -> void:
	randomize()
	is_healthy = randi() % 10 < 6 # รักษาระบบสุ่มสถานะเมล็ดเดิมไว้
