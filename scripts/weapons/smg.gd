extends Node2D

# The fire rate of the gun.
const FIRE_RATE = 0.05

# The speed of how fast the bullets travel.
const BULLET_SPEED = 420

# The spread of the bullets
const BULLET_SPREAD = 6

# The damage it deal.
const DAMAGE = 1

# How instense the shake is.
const INTENSITY = 1

# Duration of the shake.
const DURATION = 0.05

# Type of the weapon.
@export var weaponType: String = "res://scenes/weapons/smg.tscn"

# The weapon pickup type to drop.
@export var weaponTypeDrop: String = "res://scenes/weapons/smg_pickup.tscn"

# The type of weapon being utilzied pls ignore the naming.
@export var typeOfWeapon: String = "gun"

# The fire time for the time it takes to fire.
@onready var fireTimer: Timer = $FireTimer

# Camera 2D.
var camera2D: Camera2D = null

# Boolean for the fire rate.
var canShoot = true

# Ammo of the gun.
var ammo = 20

# Text version of the ammo.
var ammoText = 20

# Player reference.
var playerRef: Node = null

# This is for the enemy.
var mobRef: Node = null

# Gets the input of the player.
func getInput():
	var input = Vector2()
	
	# Make sure that it is the player.
	if playerRef:
		if Input.is_action_pressed('attack'): shoot()

	return input

# The shooting function of the gun.
func shoot():
	# Check if can shoot and check if ammo.
	if canShoot and ammo > 0:
		# Start up the bullet scene.
		var bulletScene = load("res://scenes/weapons/bullet.tscn")
		var bulletInstance = bulletScene.instantiate()
		
		# Add the bullet.
		get_parent().add_child(bulletInstance)
		bulletInstance.global_position  = $Muzzle.global_position 
		
		# Bullet spread
		var spreadRadians = deg_to_rad(randf_range(-BULLET_SPREAD, BULLET_SPREAD))
		bulletInstance.rotation = $Muzzle.global_rotation + spreadRadians
		
		# Velocity/Speed of the bullet & damage
		bulletInstance.velocity = BULLET_SPEED
		bulletInstance.damage = DAMAGE
		
		# Shake camera when the player isn't shifting.
		if !Input.is_action_pressed('ctrl'): cameraShake()
		
		# Fire rate and ammo stuff.
		canShoot = false
		ammo -= 1
		fireTimer.start()
		
	# No ammo means gun is unequipped.
	elif ammo <= 0:
		if playerRef: playerRef.onWepaonUnequipped()
		self.queue_free()
		
# The shooting function of the gun but for the goon. Crazy!
func shootGoon():
	# Check if can shoot and check if ammo.
	if canShoot and ammo > 0:
		# Start up the bullet scene.
		var bulletScene = load("res://scenes/weapons/mob_bullet.tscn")
		var bulletInstance = bulletScene.instantiate()
		
		# Add the bullet.
		get_parent().add_child(bulletInstance)
		bulletInstance.global_position  = $Muzzle.global_position 
		
		# Bullet spread
		var spreadRadians = deg_to_rad(randf_range(-BULLET_SPREAD, BULLET_SPREAD))
		bulletInstance.rotation = $Muzzle.global_rotation + spreadRadians
		
		# Velocity/Speed of the bullet & damage
		bulletInstance.velocity = BULLET_SPEED
		bulletInstance.damage = DAMAGE
		
		# Fire rate and ammo stuff.
		canShoot = false
		ammo -= 1
		fireTimer.start()
		
	# No ammo means gun is unequipped.
	elif ammo <= 0:
		#if mobRef: mobRef.onWepaonUnequipped()
		self.queue_free()

# The camera shake when shooting.
func cameraShake():
	if not camera2D: return
	var player = camera2D.get_parent()
	
	# Reset shake offset first
	player.shakeOffset = Vector2.ZERO
	player.updateCameraOffset()
	
	# Tween
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Randomize offsets a few times for shake effect
	for i in range(3):
		var randomOffset = Vector2(
			randf_range(-INTENSITY, INTENSITY),
			randf_range(-INTENSITY, INTENSITY)
		)
		tween.tween_property(camera2D, "offset", randomOffset, DURATION / 3)
		tween.tween_callback(Callable(player, "updateCameraOffset"))

func _ready() -> void:
	fireTimer.wait_time = FIRE_RATE
	
func _process(delta: float) -> void:
	getInput()
	
	if playerRef: 	look_at(get_global_mouse_position())

func _on_fire_rate_timeout() -> void:
	canShoot = true
