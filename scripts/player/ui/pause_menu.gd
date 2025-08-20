extends Node2D

# The dark overlay.
@onready var darkness = $Darkness

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
func _process(_delta): 
	if Input.is_action_just_pressed("esc"):
		get_tree().paused = !get_tree().paused
		visible = get_tree().paused
	

func _on_resume_pressed() -> void:
	get_tree().paused = !get_tree().paused
	visible = get_tree().paused

func _on_quit_pressed() -> void:
	print("Quit to main menu")
