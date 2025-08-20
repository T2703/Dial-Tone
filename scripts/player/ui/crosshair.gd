extends Node2D

func _ready() -> void:
	# Set the crosshair
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	visible = true

func _process(delta: float) -> void:
	# Follow the mouse
	global_position = get_global_mouse_position()
	
	# Toggle crosshair INVISIBLE when paused
	if get_tree().paused:
		visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Show crosshair.
	else:
		visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
