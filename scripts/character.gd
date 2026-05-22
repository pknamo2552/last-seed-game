extends CharacterBody3D

@export var speed = 5.0
@export var jump_velocity = 4.5
@export var acceleration = 10.0
@export var air_acceleration = 1.0
@export var friction = 15.0
@export var air_friction = 0.5
@export var mouse_sensitivity = 0.002
@export var ray: RayCast3D
@export var hold_position: Node3D
@export var head: Node3D
@export var camera: Camera3D
@export var throw_force = 5.0
@export var interact_label: Label
@export var inventory_ui: Control

const BLOCK_SCENE = preload("res://scenes/block.tscn")

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var held_object: RigidBody3D = null
var original_mount: Node3D = null
var inventory: Array = []
var max_inventory = 9
var is_inventory_open = false
var game_manager = null

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interact_label.visible = false
	inventory_ui.visible = false
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	var grid = inventory_ui.get_node("GridContainer")
	for i in range(grid.get_child_count()):
		var btn = grid.get_child(i)
		btn.pressed.connect(take_from_inventory.bind(i))
	
	for mount in get_tree().get_nodes_in_group("mount_point"):
		for child in mount.get_children():
			if child is RigidBody3D:
				child.freeze = true
				child.add_collision_exception_with(self)

func update_inventory_ui():
	var grid = inventory_ui.get_node("GridContainer")
	for i in range(grid.get_child_count()):
		var btn = grid.get_child(i)
		if i < inventory.size():
			var item = inventory[i]
			if item is Dictionary:
				btn.text = item.get("label", "Seed")
			elif item is String:
				btn.text = item
		else:
			btn.text = ""

func close_inventory():
	is_inventory_open = false
	inventory_ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if game_manager and (game_manager.minigame_active or game_manager.seed_minigame_active):
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89.9), deg_to_rad(89.9))

	if Input.is_action_just_pressed("toggle_cursor"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if game_manager and game_manager.showing_result:
		return

	if Input.is_action_just_pressed("interact"):
		if held_object:
			drop_object()
		else:
			try_pickup()

	if Input.is_action_just_pressed("place"):
		if held_object:
			place_object()
		else:
			try_place_seed_on_station()

	if Input.is_action_just_pressed("dig"):
		try_dig()

	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()

func try_place_seed_on_station():
	if ray.is_colliding():
		var target = ray.get_collider()
		if not is_instance_valid(target):
			return
		if target.is_in_group("station") and not target.has_seed:
			var seed_index = -1
			for i in range(inventory.size()):
				var item = inventory[i]
				if item is Dictionary and item.get("label", "") == "Seed":
					seed_index = i
					break
			if seed_index >= 0:
				var seed_data = inventory[seed_index]
				var is_healthy = seed_data["is_healthy"]
				print("placing seed is_healthy: ", is_healthy)
				target.place_seed(is_healthy)
				inventory.remove_at(seed_index)
				update_inventory_ui()

func try_dig():
	if held_object == null or not held_object.is_in_group("shovel"):
		return
	if ray.is_colliding():
		var target = ray.get_collider()
		if not is_instance_valid(target):
			return
		if target.is_in_group("diggable") and inventory.size() < max_inventory:
			randomize()
			var is_healthy = randi() % 10 < 4
			print("dug seed is_healthy: ", is_healthy)
			inventory.append({"type": "seed", "is_healthy": is_healthy, "label": "Seed"})
			target.queue_free()
			update_inventory_ui()

func toggle_inventory():
	is_inventory_open = !is_inventory_open
	inventory_ui.visible = is_inventory_open
	if is_inventory_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func take_from_inventory(index: int):
	if held_object and held_object.is_in_group("inventory_block"):
		if inventory.size() < max_inventory:
			held_object.remove_collision_exception_with(self)
			if held_object.has_meta("seed_data"):
				inventory.append(held_object.get_meta("seed_data"))
			else:
				inventory.append({"type": "seed", "is_healthy": true, "label": "Seed"})
			held_object.queue_free()
			held_object = null
			update_inventory_ui()
		close_inventory()
		return
	if held_object:
		close_inventory()
		return
	if index >= inventory.size():
		close_inventory()
		return
	var item = inventory[index]
	var block = BLOCK_SCENE.instantiate()
	get_tree().root.add_child(block)
	block.global_position = hold_position.global_position
	block.freeze = true
	block.rotation = Vector3.ZERO
	block.add_collision_exception_with(self)
	block.add_to_group("inventory_block")
	if item is Dictionary:
		block.set_meta("seed_data", item)
	held_object = block
	inventory.remove_at(index)
	update_inventory_ui()
	close_inventory()

func try_pickup():
	if ray.is_colliding():
		var target = ray.get_collider()
		if not is_instance_valid(target):
			return
		
		if target.is_in_group("seed_pod"):
			if game_manager:
				game_manager.start_seed_minigame(target)
			return
		
		if target.is_in_group("station"):
			target.inspect()
			return
		
		if target.is_in_group("bed"):
			if game_manager:
				game_manager.next_day()
			return
		
		if target.is_in_group("generator"):
			target.interact()
			return

		if target.is_in_group("furnace_button"):
			var mount = target.get_mount_point()
			if mount:
				var has_block = false
				for child in mount.get_children():
					if child is RigidBody3D:
						has_block = true
				if has_block:
					for child in mount.get_children():
						if child is RigidBody3D:
							child.queue_free()
					var furnace = target.furnace
					if furnace and furnace.has_node("FireEffect"):
						var fire = furnace.get_node("FireEffect")
						fire.visible = true
						fire.emitting = true
						await get_tree().create_timer(3.0).timeout
						fire.emitting = false
						await get_tree().create_timer(1.0).timeout
						fire.visible = false
			return

		if target is RigidBody3D:
			if target.is_in_group("diggable"):
				if held_object == null or not held_object.is_in_group("shovel"):
					return
			var parent = target.get_parent()
			if parent and parent.is_in_group("mount_point"):
				parent.remove_child(target)
				get_tree().root.add_child(target)
			original_mount = parent if parent and parent.is_in_group("mount_point") else null
			held_object = target
			held_object.freeze = true
			held_object.rotation = Vector3.ZERO
			held_object.add_collision_exception_with(self)

func drop_object():
	var obj = held_object
	held_object = null
	original_mount = null
	obj.remove_collision_exception_with(self)
	obj.freeze = false
	obj.angular_velocity = Vector3.ZERO
	obj.collision_layer = 1
	obj.collision_mask = 1
	obj.global_position = global_position + Vector3(0, 1.0, 0) + (-camera.global_transform.basis.z * 1.5)
	obj.linear_velocity = -camera.global_transform.basis.z * throw_force

func place_object():
	var mount = find_nearby_mount()
	if mount:
		var parent = held_object.get_parent()
		if parent:
			parent.remove_child(held_object)
		mount.add_child(held_object)
		held_object.freeze = true
		held_object.rotation = Vector3.ZERO
		held_object.global_position = mount.global_position
		held_object.remove_collision_exception_with(self)
		held_object.add_collision_exception_with(self)
		original_mount = null
		held_object = null
		return
	var obj = held_object
	held_object = null
	original_mount = null
	obj.remove_collision_exception_with(self)
	obj.freeze = false
	obj.angular_velocity = Vector3.ZERO
	obj.collision_layer = 1
	obj.collision_mask = 1
	obj.global_position = global_position + Vector3(0, 1.0, 0) + (-camera.global_transform.basis.z * 1.5)
	obj.linear_velocity = Vector3.ZERO

func find_nearby_mount() -> Node3D:
	for mount in get_tree().get_nodes_in_group("mount_point"):
		var dist = mount.global_position.distance_to(hold_position.global_position)
		if dist < 2.0:
			var dir_to_mount = (mount.global_position - camera.global_position).normalized()
			var look_dir = -camera.global_transform.basis.z
			var dot = look_dir.dot(dir_to_mount)
			if dot > 0.7:
				if held_object.is_in_group("shovel") and mount.is_in_group("mount_furnace"):
					continue
				if held_object.is_in_group("diggable") and not mount.is_in_group("mount_furnace"):
					continue
				if held_object.is_in_group("inventory_block") and not mount.is_in_group("mount_furnace"):
					continue
				return mount
	return null

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var blocked = game_manager and (game_manager.minigame_active or game_manager.seed_minigame_active or game_manager.station_minigame_active)
	var input_dir = Vector2.ZERO
	if not blocked:
		input_dir = Input.get_vector("left", "right", "up", "down")

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_accel = acceleration if is_on_floor() else air_acceleration
	var current_friction = friction if is_on_floor() else air_friction

	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed, current_accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, current_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)
		velocity.z = move_toward(velocity.z, 0, current_friction * delta)

	if held_object and is_instance_valid(held_object):
		held_object.global_position = hold_position.global_position
		held_object.rotation = Vector3.ZERO

	if game_manager and (game_manager.minigame_active or game_manager.seed_minigame_active or game_manager.showing_result or game_manager.station_minigame_active):
		interact_label.visible = false
	elif ray.is_colliding():
		var target = ray.get_collider()
		if not is_instance_valid(target):
			interact_label.visible = false
		elif target.is_in_group("seed_pod"):
			interact_label.text = "Press E to collect seed"
			interact_label.visible = true
		elif target.is_in_group("station"):
			if not held_object:
				if target.has_seed:
					interact_label.text = "Press E to inspect"
				else:
					var has_plain_seed = false
					for item in inventory:
						if item is Dictionary and item.get("label", "") == "Seed":
							has_plain_seed = true
							break
					if has_plain_seed:
						interact_label.text = "Press Q to place seed"
					else:
						interact_label.text = "No seed to inspect"
				interact_label.visible = true
			else:
				interact_label.visible = false
		elif target.is_in_group("bed"):
			interact_label.text = "Press E to sleep"
			interact_label.visible = true
		elif target is RigidBody3D and target.is_in_group("diggable"):
			if held_object and held_object.is_in_group("shovel"):
				interact_label.text = "Press F to dig"
				interact_label.visible = true
			elif not held_object:
				interact_label.text = "ถือพลั่วก่อน!"
				interact_label.visible = true
			else:
				interact_label.visible = false
		elif target.is_in_group("furnace_button"):
			var mount = target.get_mount_point()
			if mount:
				var has_block = false
				for child in mount.get_children():
					if child is RigidBody3D:
						has_block = true
				interact_label.text = "Press E to burn" if has_block else "No block to burn"
				interact_label.visible = true
			else:
				interact_label.visible = false
		elif target.is_in_group("generator"):
			interact_label.text = "Press E to generate power"
			interact_label.visible = true
		elif target is RigidBody3D and not held_object:
			interact_label.text = "Press E to interact"
			interact_label.visible = true
		else:
			interact_label.visible = false
	else:
		interact_label.visible = false

	move_and_slide()
