extends TextureProgressBar

# The player reference.
var playerRef


func _ready() -> void:
	playerRef = get_parent().get_parent()
