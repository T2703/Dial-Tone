extends CharacterBody2D

# How long the knockdown state lasts for.
const KNOCK_DOWN_TIME = 3

# The friction of the knockdown
const KNOCK_DOWN_FRICTION = 95

# The maximum search time for the goon.
const MAX_SEARCH_TIME = 1.5 

# The state of goon.
enum GoonState { IDLE,  PATROL, CHASING_PLAYER, GETTING_WEAPON, SEARCHING }

# The last known player position
var lastKnownPlayerPos: Vector2 = Vector2.ZERO

# Goon state.
var state = GoonState.IDLE

# SPEED OF THE ENEMY
var speed = 100

# The timer for the search.
var searchTimer = 0.0

# Health value for the goon, can be from 1 to 3.
var health = randi_range(1, 3)

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

# To keep track of the player
@onready var realPlayer: Node2D = get_tree().get_first_node_in_group("Player")

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

# The home position of the goon.
var homePos: Vector2

# The timer of the lost sight.
var lostSightTimer = 0.0

# Timer of the knockdown timer.
@onready var knockDownTimer: Timer = $KnockdownTimer

# Hitbox of the goon.
@onready var goonHitbox: Area2D = $GoonHitbox

# Detection area for player
@onready var detectionArea: Area2D = $Detection

# Knockdown area
@onready var knockdownArea: Area2D = $GoonKnockdown

# The weapon.
@export var weaponScene: PackedScene

# The ammo.
@export var startingAmmo: int

# This checks if the tile wile is matching with the player.
var isTileWallPlayer = false

# Does the goon have line of sight?
var isLineOfSight = false

func _ready():
	get_node("AnimatedSprite2D").play("idle")
	homePos = global_position
	
	if weaponScene:
		equipWeapon(weaponScene, startingAmmo)
		
	# If for some reason no weapon, go find one.
	if equippedWeapon == null:
		weaponTarget = getNearestWeapon()
		if weaponTarget:
			state = GoonState.GETTING_WEAPON

func _process(delta: float) -> void:
	if playerRef and is_instance_valid(playerRef):
		isLineOfSight = hasLineOfSight(playerRef)
		
		if isLineOfSight and state != GoonState.CHASING_PLAYER:
			state = GoonState.CHASING_PLAYER
	else:
		isLineOfSight = false
	
func _physics_process(delta: float) -> void:
	if isDead:
		return
		
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
		if playerInGoon and Input.is_action_just_pressed("space"): 
			death()
			return
	
	# Getting weapon.
	elif state == GoonState.GETTING_WEAPON and weaponTarget and is_instance_valid(weaponTarget):
		var dir = (weaponTarget.global_position - global_position).normalized()
		velocity = dir * speed
		if global_position.distance_to(weaponTarget.global_position) < 12:
			weaponTarget.pickupByMob(self)
			state = GoonState.CHASING_PLAYER
	
	# Chasing the player.
	elif state == GoonState.CHASING_PLAYER and playerRef and is_instance_valid(playerRef) and equippedWeapon:
		var distToPlayer = global_position.distance_to(playerRef.global_position)
		var dir = (playerRef.global_position - global_position).normalized()
		#print("CHASE")
		
		# Check if line of sight exists
		if isLineOfSight:
			lastKnownPlayerPos = playerRef.global_position
			lostSightTimer = 0.0
			
			# The gun logic.
			if is_instance_valid(equippedWeapon): 
				var w = equippedWeapon
				if w and w.typeOfWeapon == "gun":
					# Positions where they shoot.
					var minShootDist = 50
					var maxShootDist = 150
					
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
							var rotationSpeed = 7.5 * delta
							equippedWeapon.rotation = lerp_angle(currentAngle, targetAngle, rotationSpeed)
							
							# Make sure the aim is close 
							var aimThreshold = deg_to_rad(10)
							var angleDiff = abs(wrapf(targetAngle - equippedWeapon.rotation, -PI, PI))
							
							# Fire when they are in range of course.
							if distToPlayer < maxShootDist and angleDiff < aimThreshold:
								equippedWeapon.shootGoon()
			
				# The melee weapon logic.	
				elif w and w.typeOfWeapon == "melee":
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
						if equippedWeapon.has_node("HitDetectionPlayer"):
							equippedWeapon.hitDetectionPlayer.monitoring = false
				# No weapon, just chase
				else:
					velocity = dir * speed
		else:
			lostSightTimer += delta
			if lostSightTimer > 0.5:
				# No line of sight, go to last known position
				#print("SEARCH 1")
				state = GoonState.SEARCHING
				playerRef = null
		
	elif state == GoonState.SEARCHING:
		searchTimer += delta
		
		# Move towards the last known position.
		var dir = (lastKnownPlayerPos - global_position).normalized()
		velocity = dir * speed
		print("SEARCH 2", get_tree())
		
		if realPlayer and is_instance_valid(realPlayer):
			if hasLineOfSight(realPlayer):
				playerRef = realPlayer
				state = GoonState.CHASING_PLAYER
				searchTimer = 0.0
				print("Player rediscovered during search!")
		
		# Reaches the last known spot.
		if global_position.distance_to(lastKnownPlayerPos) < 15:
			state = GoonState.IDLE
			velocity = Vector2.ZERO
			searchTimer = 0.0
		
		# If timer runs out give up.
		elif searchTimer > MAX_SEARCH_TIME:
			state = GoonState.IDLE
			velocity = Vector2.ZERO
			searchTimer = 0.0
	
	# Normal movement if none.
	elif state == GoonState.IDLE:
		get_node("AnimatedSprite2D").play("idle")
		velocity = Vector2.ZERO
		
	move_and_slide()

# Detects the bullet.
func _on_goon_hitbox_area_entered(area: Area2D) -> void:
	if isDead:
		return
		
	# For the punch/fist.
	if area.name == "ActualPunch":
		print(area.name)
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
			return
		
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
		if is_instance_valid(weapon):
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
	if not weaponDropped and equippedWeapon and is_instance_valid(equippedWeapon):
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

# Check if the goon has line of sight on YOU.
func hasLineOfSight(target: Node2D) -> bool:
	isTileWallPlayer = false
	if not is_instance_valid(target):
		return false
		
	var spaceState = get_world_2d().direct_space_state
	
	# Create the query.
	var query = PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	query.exclude = [self]  
	query.collision_mask = 1 << 0 | 1 << 1 
	
	var result = spaceState.intersect_ray(query)
	
	# If nothing is blocking then return true.
	if result.is_empty():
		print("no block")
		return true
	# Check if the target returns the same as the collider.
	else:
		isTileWallPlayer = true
		print(result.collider == target)
		return result.collider == target
	
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
		playerRef = body  # Always track the player when inside detection
		
		# If goon has a weapon, immediately chase when LoS exists
		if equippedWeapon and is_instance_valid(equippedWeapon):
			if hasLineOfSight(body):
				state = GoonState.CHASING_PLAYER
			else:
				state = GoonState.IDLE  # in area but hidden
		else:
			# No weapon: go find one first
			weaponTarget = getNearestWeapon()
			if weaponTarget:
				state = GoonState.GETTING_WEAPON
			else:
				state = GoonState.IDLE

		# Walk animation
		if get_node("AnimatedSprite2D").animation != "death":
			get_node("AnimatedSprite2D").play("walk")

func _on_detection_body_exited(body: Node2D) -> void:
	if isDead:
		return 
		
	if body.name == "Player":
		state = GoonState.SEARCHING
		playerRef = null
		lostSightTimer = 0.0
		lastKnownPlayerPos = body.global_position
