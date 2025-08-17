extends HBoxContainer

# The player reference.
var playerRef

# The max life images.
var maxLife = 5

# The last health
var lastHealth = -1

# Load the texture.
var lifeTexture = preload("res://assets/player/ui/life.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	playerRef = get_parent().get_parent()
	updateHearts()

func _process(delta: float) -> void:
	if playerRef.health != lastHealth:
		updateHearts()

# Updates the life images based on the player's health.
func updateHearts():
	lastHealth = playerRef.health
	
	# Remove old life icons.
	for child in get_children():
		child.queue_free()
		
	# Add based on current health
	for i in range(playerRef.health):
		var life = TextureRect.new()
		life.texture = lifeTexture
		life.custom_minimum_size = Vector2(65, 65)
		add_child(life)
		
		# Animations for the last heart
		if i == playerRef.health - 1:
			var tween = create_tween().set_loops()
			tween.tween_property(life, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(life, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
