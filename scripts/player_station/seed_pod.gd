extends StaticBody3D

var is_healthy: bool = true

func _ready():
	randomize()
	is_healthy = randi() % 10 < 4

func interact() -> String:
	if is_healthy:
		return "เมล็ดพันธุ์อยู่ในสภาพดี ✓"
	else:
		return "เมล็ดพันธุ์เสียหาย! ✗"

# สุ่มใหม่ทุกครั้งที่มีการรับเมล็ด
func reset():
	is_healthy = randi() % 10 < 4
	print("seed_pod reset is_healthy: ", is_healthy)

func set_damaged():
	is_healthy = false
	var mesh = $MeshInstance3D
	var new_mat = StandardMaterial3D.new()
	new_mat.albedo_color = Color.BLACK
	mesh.set_surface_override_material(0, new_mat)
