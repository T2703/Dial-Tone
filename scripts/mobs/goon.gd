extends CharacterBody2D

# How long the knockdown state lasts for.
const KNOCK_DOWN_TIME = 3

# The friction of the knockdown
const KNOCK_DOWN_FRICTION = 95

# The state of goon.
enum GoonState { IDLE,  PATROL, CHASING_PLAYER, GETTING_WEAPON }

# Goon state.
var state = GoonState.IDLE

# SPEED OF THE ENEMY
var speed = 100

# Health value for the goon, can be from 1 to 5.
var health = randi_range(1, 5)

# Check if the player is located inside of the goon.
var playerInGoon = false

# Check the knockdown.
var isKnockdown = false

# Knockdown velocity.
var knockdownVelocity = Vector2.ZERO

# Strength of the knockback.
var knockBackStrength = randi_range(60, 85)

# Check if goon can chase.
var canChase = false

# The equipped weapon.
var equippedWeapon: Node = null

# The reference of the player for chasing.
var playerRef: Node2D = null

# The target of the weapon for chasing.
var weaponTarget: Node2D = null

# The equipped weapon.
@onready var heldWeapon: Node2D = $HeldWeapon

# Cool down for the equip so it doesn't drop instantly.
var equipCooldown = 0.2

# The time to equip.
var equipTimer = 0.0

# Weapon path of the last weapon.
var lastWeaponTypePath: String = ""

# The amount of ammo it had.
var lastWeaponAmmo: int = 0

# Checks if the weapon has been dropped.
var weaponDropped = false

# Check if goon is dead.
var isDead = false

# Timer of the knockdown timer.
@onready var knockDownTimer: Timer = $KnockdownTimer

# Hitbox of the goon.
@onready var goonHitbox: Area2D = $GoonHitbox

# The weapon.
@export var weaponScene: PackedScene

# The ammo.
@export var startingAmmo: int

func _ready():
	get_node("AnimatedSprite2D").play("idle")
	
	if weaponScene:
		equipWeapon(weaponScene, startingAmmo)
		
	# If for some reason no weapon, go find one.
	if equippedWeapon == null:
		weaponTarget = getNearestWeapon()
		if weaponTarget:
			state = GoonState.GETTING_WEAPON
	
func _physics_process(delta: float) -> void:
	# Make sure this gets reenabled.
	if not isKnockdown and is_instance_valid(goonHitbox):
		if not goonHitbox.monitoring:
			goonHitbox.monitoring = true
		
	# If goon has no weapon and no current weapon target, find one.
	if equippedWeapon == null and weaponTarget == null:
		weaponTarget = getNearestWeapon()
		if weaponTarget:
			state = GoonState.GETTING_WEAPON
	
	# Apply the friction if knocked down so the body stops.
	if isKnockdown:
		knockdownVelocity = knockdownVelocity.move_toward(Vector2.ZERO, KNOCK_DOWN_FRICTION * delta)
		velocity = knockdownVelocity
		dropWeapon()
		
		# Check for the execution.
		if playerInGoon and Input.is_action_just_pressed("space"): death()
	
	# Getting weapon.
	elif state == GoonState.GETTING_WEAPON and weaponTarget:
		var dir = (weaponTarget.global_position - global_position).normalized()
		velocity = dir * speed
		if global_position.distance_to(weaponTarget.global_position) < 12:
			weaponTarget.pickupByMob(self)
			state = GoonState.CHASING_PLAYER
		
	# Chasing the player.
	elif state == GoonState.CHASING_PLAYER and playerRef:
		var distToPlayer = global_position.distance_to(playerRef.global_position)
		var dir = (playerRef.global_position - global_position).normalized()
		velocity = dir * speed
		
		
		# The gun logic.
		if equippedWeapon.typeOfWeapon == "gun":
			# Positions where they shoot.
			var minShootDist = 40
			var maxShootDist = 120
			
			# Movement logic
			if distToPlayer > maxShootDist:
				# Too far, move closer.
				velocity = dir * speed
			elif distToPlayer < minShootDist:
				# Too close, back up.
				velocity = -dir * speed * 0.75
			else:
				# Stand still
				velocity = Vector2.ZERO
			
			# Aim.
			if equippedWeapon and is_instance_valid(equippedWeapon):		
				# Smooth Aim.
				var targetAngle = (playerRef.global_position - equippedWeapon.global_position).angle()
				var currentAngle = equippedWeapon.rotation
				var rotationSpeed = 3.5 * delta
				equippedWeapon.rotation = lerp_angle(currentAngle, targetAngle, rotationSpeed)
				
				# Make sure the aim is close 
				var aimThreshold = deg_to_rad(10)
				var angleDiff = abs(wrapf(targetAngle - equippedWeapon.rotation, -PI, PI))
				
				# Fire when they are in range of course.
				if distToPlayer < maxShootDist and angleDiff < aimThreshold:
					equippedWeapon.shootGoon()
		
		# The melee weapon logic.	
		elif equippedWeapon.typeOfWeapon == "melee":
			var swingDist = 30
			
			# Rotate to the player
			var targetAngle = (playerRef.global_position - equippedWeapon.global_position).angle()
			var currentAngle = equippedWeapon.rotation
			var rotationSpeed = 3.5 * delta
			equippedWeapon.rotation = lerp_angle(currentAngle, targetAngle, rotationSpeed)
			
			# Swing when close
			if distToPlayer < swingDist:
				velocity = Vector2.ZERO
				equippedWeapon.swingGoon()
			else:
				equippedWeapon.hitDetectionPlayer.monitoring = false
				equippedWeapon.hitDetectionPlayer.monitoring = false
	
	# Normal movement if none.
	else:
		state = GoonState.IDLE
		get_node("AnimatedSprite2D").play("idle")
		velocity = Vector2.ZERO
		
	move_and_slide()

# Detects the bullet.
func _on_goon_hitbox_area_entered(area: Area2D) -> void:
	# For the punch/fist.
	if area.name == "Punch":
		isKnockdown = true
		
		# Get the player.
		var player = area.get_parent()
		
		# Directoin from this player to goon.
		var dir = (global_position - player.global_position).normalized()
		
		# Start up the timer for knockown
		knockDownTimer.wait_time = KNOCK_DOWN_TIME
		knockDownTimer.start()
		
		# Apply the strength of knockback.
		knockdownVelocity = dir * knockBackStrength
		
		# Disable the hitbox
		goonHitbox.set_deferred("monitoring", false)
		
		# Play the knockdown animation.
		get_node("AnimatedSprite2D").play("knockdown")
		
	# For the bullet.
	elif area.name == "BulletHit":		
		# Get the main node.
		var bulletNode = area.get_parent()
		
		# Gets the damage of the bullet which is from the gun.
		var bulletDamage = bulletNode.getDamage()
		health -= bulletDamage
		
		# Death upon 0 health.
		if health <= 0:
			dropWeapon()
			death()
		
		# Clear the bullet.
		bulletNode.queue_free()
	
	# Melee hit they die in one blow.
	elif area.name == "HitDetection": 
		death()

# The death of goon.
func death():
	if isDead:
		return 
		
	isDead = true
	speed = 0
	goonHitbox.set_deferred("monitoring", false)
	
	# Drop the weapon if still holding it OR if we saved it from knockdown and if the hasn't been dropped yet.
	if not weaponDropped:
		if equippedWeapon and is_instance_valid(equippedWeapon):
			dropWeapon()
		elif lastWeaponTypePath != "" and not weaponDropped:
			spawnWeaponPickup(lastWeaponTypePath, lastWeaponAmmo)
			weaponDropped = true
		
	get_node("AnimatedSprite2D").play("death")
	await get_node("AnimatedSprite2D").animation_finished
	self.queue_free()

# This makes the goon go for the nearest weapon.
func getNearestWeapon() -> Area2D:
	# Check for any weapons
	var weapons = get_tree().get_nodes_in_group("Weapons")
	if weapons.is_empty():
		state = GoonState.IDLE
		return null
		
	# Find the nearest weapon.
	var nearest = null
	var nearestDist = INF
	
	# Loop through the weapons to find the nearest one.
	for weapon in weapons:
		var dist = global_position.distance_to(weapon.global_position)
		if dist < nearestDist:
			nearestDist = dist
			nearest = weapon
	
	return nearest
	
# How the player equips the weapon.
func equipWeapon(weaponScene: PackedScene, ammo: int) -> void:
	equipTimer = equipCooldown
	weaponDropped = false
	
	# This adds the weapon to the goon.
	equippedWeapon = weaponScene.instantiate()
	equippedWeapon.position = Vector2(-10, 0)
	
	# This makes the ammo stay the same (No infintes) & Send the goon.
	equippedWeapon.mobRef = self
	equippedWeapon.ammo = ammo
	heldWeapon.add_child(equippedWeapon)

# The function for dropping weapons.
func dropWeapon():
	if not weaponDropped and is_instance_valid(equippedWeapon):
		# Saving the weapon from death.
		lastWeaponTypePath = equippedWeapon.weaponTypeDrop
		lastWeaponAmmo = equippedWeapon.ammo
		
		# Spawn dat.
		spawnWeaponPickup(lastWeaponTypePath, lastWeaponAmmo)
		weaponDropped = true
		
		# Remove the weapon from the mob
		equippedWeapon.queue_free()
		equippedWeapon = null

# For spawning the weapon when death or knocked.
func spawnWeaponPickup(path: String, ammo: int):
	if path == "": return
		
	var weaponScene = load(path)
	var droppedPickup = weaponScene.instantiate()
	droppedPickup.ammo = ammo
	droppedPickup.global_position = global_position + Vector2(0, 10)
	get_tree().current_scene.call_deferred("add_child", droppedPickup)

# Once done the knockdown boolean resets and other properties
func _on_knockdown_timer_timeout() -> void:
	if isDead:
		return 
		
	isKnockdown = false
	goonHitbox.set_deferred("monitoring", true)
	
	# Get weapon when not having one.
	if state != GoonState.GETTING_WEAPON and equippedWeapon == null:
		weaponTarget = getNearestWeapon()
		if weaponTarget:
			state = GoonState.GETTING_WEAPON
			
	# Play the walk animation.
	if get_node("AnimatedSprite2D").animation != "death":
		get_node("AnimatedSprite2D").play("idle")

# For the player when knocked down.
func _on_goon_knockdown_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		playerInGoon = true

func _on_goon_knockdown_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		playerInGoon = false
	
# Detect player
func _on_detection_body_entered(body: Node2D) -> void:
	if isDead:
		return 
		
	if body.name == "Player":
		playerRef = body
		
		# Get weapon when not having one.
		if equippedWeapon == null:
			weaponTarget = getNearestWeapon()
			if weaponTarget:
				state = GoonState.GETTING_WEAPON
			else: 
				state = GoonState.IDLE
		else:
			state = GoonState.CHASING_PLAYER
		
		# Play the walk animation.
		if get_node("AnimatedSprite2D").animation != "death":
			get_node("AnimatedSprite2D").play("walk")

func _on_detection_body_exited(body: Node2D) -> void:
	if isDead:
		return 
		
	if body.name == "Player":
		state = GoonState.IDLE
		playerRef = null
		
		# Only reset state/animation if not knocked down.
		if not isKnockdown:
			state = GoonState.IDLE
			if get_node("AnimatedSprite2D").animation != "death":
				get_node("AnimatedSprite2D").play("idle")
