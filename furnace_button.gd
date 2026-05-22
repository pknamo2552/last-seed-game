extends StaticBody3D

@export var furnace: Node3D  # ลาก Furnace มาใส่ใน Inspector

func get_mount_point() -> Node3D:
	if furnace and furnace.has_node("MountPoint"):
		return furnace.get_node("MountPoint")
	return null
