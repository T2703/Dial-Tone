extends CharacterBody2D

# Speed of the player movement.
const SPEED = 175

# Accleration of the player.
const ACCELERATION = 0.2

# Movement friction for sliding and moving.
const FRICTION = 1

# How far the player can punch.
const MAX_PUNCH_DISTANCE = 30

# How far the player can look ahead.
const LOOK_AHEAD_DISTANCE = 105

# Animation of the player.
@onready var anim = get_node("AnimationPlayer")

# The equipped weapon.
@onready var heldWeapon: Node2D = $HeldWeapon

# The equipped weapon.
var equippedWeapon: Node = null

# The current weapon picked up.
var currentWeaponPickupScene: PackedScene = null

# Checks if the player can throw a punch.
var canFist = true

# Cool down for the equip so it doesn't drop instantly.
var equipCooldown = 0.2

# The time to equip.
var equipTimer = 0.0

# Health of the player
var health = 5

# Offset look
var lookOffset: Vector2 = Vector2.ZERO

# Offset 
var shakeOffset: Vector2 = Vector2.ZERO

func _ready() -> void:
	get_viewport().focus_entered.connect(_on_window_focus_in)
	get_viewport().focus_exited.connect(_on_window_focus_out)
	
# Gets the input of the player.
func getInput():
	# Movement
	var input = Input.get_vector("left", "right", "up", "down")
	
	# Attack
	if Input.is_action_just_pressed("attack") and canFist: punch()
	
	# Drop weapon
	if Input.is_action_just_pressed("rclick") and equippedWeapon and equipTimer <= 0.0: dropWeapon()
		
	return input

# This is the punch attack.
func punch() -> void:
	var punchScene = load("res://scenes/player/punch.tscn")
	var punchInstance = punchScene.instantiate()
	
	# Get the mouse position.
	var mousePos = get_global_mouse_position()
	var dir = mousePos - global_position
	
	# Limit the length where it spawns
	var spawnOffset = dir.limit_length(MAX_PUNCH_DISTANCE) 
	var spawnPos = global_position + spawnOffset

	# Add the punch.
	self.add_child(punchInstance)
	punchInstance.global_position = spawnPos
	
	# Despawn after 0.05 seconds
	var timer = Timer.new()
	timer.wait_time = 0.05
	timer.one_shot = true
	timer.connect("timeout", Callable(punchInstance, "queue_free"))
	punchInstance.add_child(timer)
	timer.start()

# How the player equips the weapon.
func equipWeapon(weaponScene: PackedScene, ammo: int) -> void:
	canFist = false
	equipTimer = equipCooldown
	
	# Swap the weapon out.
	if equippedWeapon and is_instance_valid(equippedWeapon):
		dropWeaponWithoutFist()
	equippedWeapon = null
	
	# This adds the weapon to the player.
	equippedWeapon = weaponScene.instantiate()
	equippedWeapon.position = Vector2(-10, 0)
	
	# This makes the ammo stay the same (No infintes).
	equippedWeapon.ammo = ammo
	heldWeapon.add_child(equippedWeapon)
	
	# Put on the player reference.
	equippedWeapon.playerRef = self
	equippedWeapon.camera2D = $Camera2D
	currentWeaponPickupScene = weaponScene


# This function helps with re enabling punching.
func onWepaonUnequipped() -> void:
	canFist = true
	equippedWeapon = null

# The function for dropping weapons.
func dropWeapon():
	if equippedWeapon and is_instance_valid(equippedWeapon):
		# Saving the stats.
		var pickupPath = equippedWeapon.weaponTypeDrop
		var weaponScene = load(pickupPath)
		var droppedPickup = weaponScene.instantiate()
		
		# Passing weapon state to the pickup script.
		droppedPickup.ammo = equippedWeapon.ammo
		droppedPickup.weaponType = equippedWeapon.scene_file_path
		
		# Spawn it.
		droppedPickup.global_position = global_position + Vector2(0, 10)
		get_tree().current_scene.add_child(droppedPickup)
		
		# Remove the weapon from the player
		equippedWeapon.queue_free()
		equippedWeapon = null
		canFist = true

# The function for dropping weapons without setting canFist to true.
func dropWeaponWithoutFist():
	if equippedWeapon and is_instance_valid(equippedWeapon):
		# Saving the stats.
		var pickupPath = equippedWeapon.weaponTypeDrop
		var weaponScene = load(pickupPath)
		var droppedPickup = weaponScene.instantiate()
		
		# Passing weapon state to the pickup script.
		droppedPickup.ammo = equippedWeapon.ammo
		droppedPickup.weaponType = equippedWeapon.scene_file_path
		
		# Spawn it.
		droppedPickup.global_position = global_position + Vector2(0, 10)
		get_tree().current_scene.add_child(droppedPickup)
		
		# Remove the weapon from the player
		equippedWeapon.queue_free()
		equippedWeapon = null

# This function updates the camera position, it makes the player look ahead.
func updateCameraPos():
	var mouseDir = (get_global_mouse_position() - global_position).normalized()
	lookOffset = mouseDir * LOOK_AHEAD_DISTANCE
	updateCameraOffset()
	
# The death of player 456.
func death():
	#get_node("AnimatedSprite2D").play("death")
	#await get_node("AnimatedSprite2D").animation_finished
	self.queue_free()

# Reset the camera postion back to the player.
func resetCameraPos(delta):
	lookOffset = lookOffset.lerp(Vector2.ZERO, delta * 10)
	updateCameraOffset()

# Combines the offsets.
func updateCameraOffset():
	$Camera2D.offset = lookOffset + shakeOffset
	
func _process(delta: float) -> void:
	if not get_viewport().has_focus():
		velocity = Vector2.ZERO
		anim.play("idle")
		Input.action_release("up")
		Input.action_release("down")
		Input.action_release("left")
		Input.action_release("right")
		Input.action_release("attack")
		Input.action_release("rclick")
		return
	# Decrease the equip timer.
	if equipTimer > 0: equipTimer -= delta
		
	# The only time where the input is needed here because delta.
	# Look ahead and reset if not shift
	if Input.is_action_pressed("shift"): updateCameraPos()
	elif !Input.is_action_pressed("shift"): resetCameraPos(delta)
		
# This does the movement
func _physics_process(delta: float) -> void:
	if not get_viewport().has_focus():
		velocity = Vector2.ZERO
		anim.play("idle")
		Input.action_release("up")
		Input.action_release("down")
		Input.action_release("left")
		Input.action_release("right")
		Input.action_release("attack")
		Input.action_release("rclick")
		return
		
	var direction = getInput()
	
	if direction.length() > 0:
		velocity = velocity.lerp(direction.normalized() * SPEED, ACCELERATION)
		anim.play("walk")
	else:
		velocity = velocity.lerp(Vector2.ZERO, FRICTION)
		anim.play("idle")
		
	move_and_slide()

# Bullet hit
func _on_player_hitbox_area_entered(area: Area2D) -> void:
	# For the bullet.
	if area.name == "MobBulletHit":
		# Get the main node.
		var bulletNode = area.get_parent()
		
		# Gets the damage of the bullet which is from the gun.
		var bulletDamage = bulletNode.getDamage()
		health -= bulletDamage
			
		# Death upon 0 health.
		if health <= 0:
			death()
		
		# Clear the bullet.
		bulletNode.queue_free()
	
	# Melee equals die in on hit.
	elif area.name == "HitDetectionPlayer": self.queue_free()

func _on_window_focus_in():
	velocity = Vector2.ZERO
	Input.action_release("up")
	Input.action_release("down")
	Input.action_release("left")
	Input.action_release("right")
	Input.action_release("attack")
	Input.action_release("rclick")
	anim.play("idle")
	print("Window has gained focus.")

func _on_window_focus_out():
	velocity = Vector2.ZERO
	Input.action_release("up")
	Input.action_release("down")
	Input.action_release("left")
	Input.action_release("right")
	Input.action_release("attack")
	Input.action_release("rclick")
	anim.play("idle")
	print("Window has lost focus.")
