extends Node2D

# How far the player can bat.
const MAX_BAT_DISTANCE = 15

# The durablity of the melee weapon.
var ammo = 8

# Text version of the ammo.
var ammoText = 8

# Type of the weapon.
@export var weaponType: String = "res://scenes/weapons/bat.tscn"

# The weapon pickup type to drop.
@export var weaponTypeDrop: String = "res://scenes/weapons/bat_pickup.tscn"

# The type of weapon being utilzied pls ignore the naming.
@export var typeOfWeapon: String = "melee"

# The hit cooldown timer.
@onready var hitCooldown: Timer = $HitCooldown

# Hitbox of the bat.
@onready var hitDetection: Area2D = $HitDetection

# Hitbox of the bat goon edition.
@onready var hitDetectionPlayer: Area2D = $HitDetectionPlayer

# Player reference.
var playerRef: Node = null

# This is for the enemy.
var mobRef: Node = null

# Camera 2D. (I need this, the code is kinda bad).
var camera2D: Camera2D = null

# Cooldown for the hit so it does lose life rapidly.
var hitOnCooldown = false

# Gets the input of the player.
func getInput():
	var input = Vector2()
	
	# Make sure that it is the player.
	if playerRef:
		if Input.is_action_pressed('attack'): swing()
		else: 
			hitDetection.monitoring = false
			hitDetection.monitorable = false
			position = Vector2.ZERO
			
	return input

# The melee attack.
func swing():
	hitDetection.monitoring = true
	hitDetection.monitorable = true
	
	# Get direction from player to mouse.
	var mousePos = get_global_mouse_position()
	var dir = (mousePos - playerRef.global_position).normalized()
	
	# Position bat at max distance from player.
	position = dir * MAX_BAT_DISTANCE
	
	# Tween swing.
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Start rotation
	var startRot = rotation
	
	# Swing forwards and backwards
	tween.tween_property(self, "rotation", startRot + deg_to_rad(180), 0.1)
	tween.tween_property(self, "rotation", startRot, 0.1)

	# No ammo means melee is unequipped.
	if ammo <= 0:
		if playerRef: playerRef.onWepaonUnequipped()
		self.queue_free()
		
# The swing function of the melee but for the goon. Crazy!
func swingGoon():
	hitDetectionPlayer.monitoring = true
	hitDetectionPlayer.monitorable = true
	
	# Get direction from player to mouse.
	var dir = (mobRef.playerRef.global_position - mobRef.global_position).normalized()
	
	# Position bat at max distance from player.
	position = dir
	
	# Tween swing.
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Start rotation
	var startRot = rotation
	
	# Swing forwards and backwards
	tween.tween_property(self, "rotation", startRot + deg_to_rad(180), 0.1)
	tween.tween_property(self, "rotation", startRot, 0.1)

	# No ammo means melee is unequipped.
	if ammo <= 0:
		self.queue_free()

# Set the owner of this weapon.
func setOwner(owner: Node):
	if hitDetection:
		hitDetection.connect("body_entered", Callable(self, "_on_hit_detection_body_entered").bind(owner))
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hitDetection.monitoring = false
	hitDetection.monitorable = false
	hitDetection.set_deferred("monitoring", false)
	hitDetection.set_deferred("monitoring", false)
	
	hitDetectionPlayer.monitoring = false
	hitDetectionPlayer.monitorable = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	getInput()
	
# Lose 1 health when killing an enemy.
func _on_hit_detection_body_entered(body: Node2D) -> void:
	if body == owner:
		return
		
	if body.name == "Goon" and not hitOnCooldown and not body.isKnockdown:
		print("Bat")
		ammo -= 1
		hitOnCooldown = true
		hitCooldown.start()

func _on_hit_cooldown_timeout() -> void:
	hitOnCooldown = false


func _on_hit_detection_player_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not hitOnCooldown:
		ammo -= 1
		hitOnCooldown = true
		hitCooldown.start()
