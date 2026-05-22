extends Interactable

func _ready():
	prompt_message = "Press E to generate power"

func interact(player: CharacterBody3D) -> void:
	if player.game_manager:
		player.game_manager.start_minigame()
