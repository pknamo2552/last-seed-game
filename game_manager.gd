extends Node3D

var energy: float = 100.0
var energy_drain_rate: float = 0.5
var energy_warning: float = 30.0
var is_game_over: bool = false
var current_day: int = 1
var max_days: int = 3
var minigame_active: bool = false
var button_sequence: Array = []
var current_input_index: int = 0
var sequence_length: int = 4
var minigame_time: float = 10.0
var minigame_timer: float = 0.0
var seed_minigame_active: bool = false
var current_seed_pod = null
var showing_result: bool = false

var station_minigame_active: bool = false
var current_station = null
var station_dots: Array = []
var station_dot_count: int = 0
var station_timer: float = 10.0
var station_timer_current: float = 0.0

@onready var energy_bar = $CanvasLayer/EnergyBar
@onready var day_label = $CanvasLayer/DayLabel
@onready var minigame_panel = $CanvasLayer/MinigamePanel
@onready var button_prompt = $CanvasLayer/MinigamePanel/ButtonPrompt
@onready var station_minigame_ui = $CanvasLayer/StationMinigame
@onready var timer_label = $CanvasLayer/StationMinigame/TimerLabel

var button_keys = ["F", "Q", "R", "T", "G", "Z", "X", "C", "V", "B"]

func _ready():
	randomize()
	minigame_panel.visible = false
	station_minigame_ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	update_ui()
	
func _process(delta):
	if is_game_over:
		return
	
	energy -= energy_drain_rate * delta
	energy = clamp(energy, 0, 100)
	update_ui()
	
	if energy <= energy_warning:
		day_label.modulate = Color.RED
	else:
		day_label.modulate = Color.WHITE
	
	if energy <= 0:
		game_over()
	
	if minigame_active or seed_minigame_active:
		minigame_timer -= delta
		if minigame_timer <= 0:
			fail_minigame()
	
	if station_minigame_active:
		station_timer_current -= delta
		if timer_label:
			timer_label.text = "Time: %.1f" % station_timer_current
		if station_timer_current <= 0:
			fail_station_minigame()

func update_ui():
	energy_bar.value = energy
	day_label.text = "Day %d / %d" % [current_day, max_days]

func next_day():
	if current_day >= max_days:
		good_ending()
		return
	current_day += 1
	energy = 100.0
	update_ui()

func start_minigame():
	if minigame_active or seed_minigame_active or showing_result or station_minigame_active:
		return
	minigame_active = true
	current_input_index = 0
	minigame_timer = minigame_time
	button_sequence.clear()
	for i in range(sequence_length):
		button_sequence.append(button_keys[randi() % button_keys.size()])
	minigame_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	show_current_prompt()

func start_seed_minigame(seed_pod):
	if minigame_active or seed_minigame_active or showing_result or station_minigame_active:
		return
	seed_minigame_active = true
	current_seed_pod = seed_pod
	current_input_index = 0
	minigame_timer = minigame_time
	button_sequence.clear()
	for i in range(sequence_length):
		button_sequence.append(button_keys[randi() % button_keys.size()])
	minigame_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	button_prompt.text = "กดรับเมล็ด Press: " + button_sequence[0]

func start_station_minigame(station):
	if minigame_active or seed_minigame_active or showing_result or station_minigame_active:
		return
	station_minigame_active = true
	current_station = station
	station_timer_current = station_timer
	station_dot_count = randi_range(3, 7)
	station_minigame_ui.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	spawn_next_dot()

func spawn_next_dot():
	for dot in station_dots:
		if is_instance_valid(dot):
			dot.queue_free()
	station_dots.clear()
	
	if station_dot_count <= 0:
		success_station_minigame()
		return
	
	var dot = Button.new()
	var size = randi_range(30, 80)
	dot.custom_minimum_size = Vector2(size, size)
	
	var screen_size = get_viewport().get_visible_rect().size
	var x = randi_range(size, int(screen_size.x) - size)
	var y = randi_range(size, int(screen_size.y) - size)
	dot.position = Vector2(x, y)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color.RED
	style.corner_radius_top_left = 50
	style.corner_radius_top_right = 50
	style.corner_radius_bottom_left = 50
	style.corner_radius_bottom_right = 50
	dot.add_theme_stylebox_override("normal", style)
	dot.add_theme_stylebox_override("hover", style)
	dot.add_theme_stylebox_override("pressed", style)
	dot.text = ""
	
	station_minigame_ui.add_child(dot)
	station_dots.append(dot)
	dot.pressed.connect(_on_dot_clicked)
	station_dot_count -= 1

func _on_dot_clicked():
	spawn_next_dot()

func success_station_minigame():
	station_minigame_active = false
	station_minigame_ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if current_station and is_instance_valid(current_station):
		var is_healthy = current_station.seed_is_healthy
		current_station.remove_seed()
		var player = get_tree().get_first_node_in_group("player")
		if player and player.inventory.size() < player.max_inventory:
			var seed_label = "Good Seed" if is_healthy else "Bad Seed"
			player.inventory.append({"type": "seed", "is_healthy": is_healthy, "label": seed_label})
			player.update_inventory_ui()
		if is_healthy:
			show_result("เมล็ดพันธุ์ปกติ ✓ ได้รับ Good Seed")
		else:
			show_result("เมล็ดพันธุ์ผิดปกติ! ✗ ได้รับ Bad Seed")
	current_station = null

func fail_station_minigame():
	station_minigame_active = false
	station_minigame_ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for dot in station_dots:
		if is_instance_valid(dot):
			dot.queue_free()
	station_dots.clear()
	if current_station and is_instance_valid(current_station):
		var is_healthy = current_station.seed_is_healthy
		current_station.remove_seed()
		var player = get_tree().get_first_node_in_group("player")
		if player and player.inventory.size() < player.max_inventory:
			player.inventory.append({"type": "seed", "is_healthy": is_healthy, "label": "Unknown Seed"})
			player.update_inventory_ui()
	current_station = null
	show_result("ตรวจสอบไม่ได้! ได้รับ Unknown Seed")

func cancel_minigame():
	if not minigame_active and not seed_minigame_active:
		return
	minigame_active = false
	seed_minigame_active = false
	current_seed_pod = null
	minigame_panel.visible = false

func show_current_prompt():
	if current_input_index < button_sequence.size():
		if seed_minigame_active:
			button_prompt.text = "กดรับเมล็ด Press: " + button_sequence[current_input_index]
		else:
			button_prompt.text = "Press: " + button_sequence[current_input_index]

func _input(event):
	if not minigame_active and not seed_minigame_active:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		var key_str = OS.get_keycode_string(event.keycode)
		
		if key_str == "E":
			fail_minigame()
			get_viewport().set_input_as_handled()
			return
		
		if key_str == button_sequence[current_input_index]:
			current_input_index += 1
			if current_input_index >= button_sequence.size():
				success_minigame()
			else:
				show_current_prompt()
		else:
			fail_minigame()
		
		get_viewport().set_input_as_handled()

func success_minigame():
	if seed_minigame_active:
		seed_minigame_active = false
		if current_seed_pod and is_instance_valid(current_seed_pod):
			var player = get_tree().get_first_node_in_group("player")
			if player and player.inventory.size() < player.max_inventory:
				player.inventory.append({"type": "seed", "is_healthy": current_seed_pod.is_healthy, "label": "Seed"})
				player.update_inventory_ui()
				show_result("ได้รับเมล็ด")
			else:
				show_result("กระเป๋าเต็ม")
			# สุ่มใหม่หลังรับเมล็ด
			current_seed_pod.reset()
		current_seed_pod = null
	else:
		minigame_active = false
		minigame_panel.visible = false
		energy = min(energy + 50.0, 100.0)
		update_ui()
		
func fail_minigame():
	if seed_minigame_active:
		seed_minigame_active = false
		show_result("ล้มเหลว!")
		current_seed_pod = null
	else:
		minigame_active = false
		minigame_panel.visible = false

func show_result(text: String):
	showing_result = true
	minigame_panel.visible = true
	button_prompt.text = text
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await get_tree().create_timer(3.0).timeout
	minigame_panel.visible = false
	showing_result = false

func game_over():
	is_game_over = true
	for pod in get_tree().get_nodes_in_group("seed_pod"):
		if pod.has_method("set_damaged"):
			pod.set_damaged()
	print("GAME OVER!")

func good_ending():
	print("GOOD ENDING!")
