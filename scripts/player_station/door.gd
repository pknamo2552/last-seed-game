extends AnimatableBody3D

@export var open_position: Vector3 = Vector3(2, 0, 0)
@export var speed: float = 3.0
@export var detect_area: Area3D  # ← ช่องนี้จะโผล่ใน Inspector

var closed_position: Vector3
var target_position: Vector3
var player_inside: bool = false

func _ready():
	closed_position = position
	target_position = closed_position
	detect_area.body_entered.connect(_on_entered)
	detect_area.body_exited.connect(_on_exited)

func _physics_process(delta):
	target_position = closed_position + open_position if player_inside else closed_position
	if position.distance_to(target_position) > 0.01:
		position = position.lerp(target_position, speed * delta)
	else:
		position = target_position

func _on_entered(body):
	if body is CharacterBody3D:
		player_inside = true

func _on_exited(body):
	if body is CharacterBody3D:
		player_inside = false
