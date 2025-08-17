extends Node2D

# List of room scenes for the level to generate.
var roomScenes = [
	preload("res://scenes/levels/rooms/room_one.tscn"),
	preload("res://scenes/levels/rooms/room_two.tscn")
]

# The list of rooms that have been generated.
var generatedRooms = []

# The last room.
var lastRoom = null

func _ready() -> void:
	randomize()
	generateLevel(5)
	
func generateLevel(roomCount: int):
	# Add rooms based on the room count
	for i in range(roomCount):
		# Initializing the rooms.
		var roomScene = roomScenes[randi() % roomScenes.size()]
		var room = roomScene.instantiate()
		
		# First room, origin room.
		if lastRoom == null:
			room.position = Vector2.ZERO
			add_child(room)
			generatedRooms.append(room)
			lastRoom = room
		# Random room to be generated.
		else:
			# Placement and tries
			var placed = false
			var tries = 0
			
			# Place down when it isn't placed yet and we still have tries.
			while not placed and tries < 10:
				tries += 1
				# Choosing door.
				var exitDoor = pickRanDoor(lastRoom)
				var entryDoor = findOppDoor(room, exitDoor.name)
				
				# Allignment
				var offset = exitDoor.global_position - entryDoor.position
				room.position = offset 
				
				# Check overlap
				if not isOverlapping(room):
					add_child(room)
					generatedRooms.append(room)
					lastRoom = room
					placed = true
				else:
					# Retry.
					room.queue_free()
					room = roomScenes[randi() % roomScenes.size()].instantiate()
			if not placed:
				print("⚠️ Couldn’t place room after several tries, skipping.")

# Pick a random door for the last room
func pickRanDoor(room: Node) -> Node2D:
	var doors = []
	for c in room.get_children():
		if c.name.begins_with("Door"):
			doors.append(c)
	return doors[randi() % doors.size()]

# The mapping of doors to their opposites.
func findOppDoor(room: Node, exit_name: String) -> Node2D:
	var opposite = {
		"DoorTop": "DoorBottom",
		"DoorBottom": "DoorTop",
	}
	return room.get_node(opposite.get(exit_name, "DoorTop"))

# This check if the room is overlapping.
func isOverlapping(newRoom: Node2D) -> bool:
	var newBounds = newRoom.get_node("Bounds/CollisionShape2D") as CollisionShape2D
	var newRect = Rect2(newRoom.global_position, newBounds.shape.extents * 2)

	for room in generatedRooms:
		var roomBounds = room.get_node("Bounds/CollisionShape2D") as CollisionShape2D
		var roomRect = Rect2(room.global_position, roomBounds.shape.extents * 2)

		if newRect.intersects(roomRect):
			return true

	return false
