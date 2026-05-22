extends StaticBody3D

var player_nearby: bool = false
var game_manager = null

@onready var detect_area: Area3D = $DetectArea

func _ready():
	detect_area.body_entered.connect(_on_body_entered)
	detect_area.body_exited.connect(_on_body_exited)
	game_manager = get_tree().get_first_node_in_group("game_manager")

func _on_body_entered(body):
	if body is CharacterBody3D:
		player_nearby = true

func _on_body_exited(body):
	if body is CharacterBody3D:
		player_nearby = false
		# ซ่อน minigame ถ้าเดินออก
		if game_manager:
			game_manager.cancel_minigame()

func interact():
	if game_manager:
		game_manager.start_minigame()
