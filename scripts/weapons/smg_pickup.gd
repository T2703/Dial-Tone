extends Area2D

# The rotation speed of the pickup.
const ROTATE_SPEED = 2.5

# The SMG scene.
@export var SMG: PackedScene

# Ammo they packing.
@export var ammo: int = 20

# Type of the weapon.
@export var weaponType: String = "res://scenes/weapons/smg.tscn"

# The weapon that should be dropped.
@export var weaponTypeDrop: String = "res://scenes/weapons/smg_pickup.tscn"

# Check if in the pickup area.
var inPickupArea = false

# The player reference.
var playerRef = null

# This is the pickup/equip for enemies/mobs.
func pickupByMob(mob) -> void:
	mob.equipWeapon(SMG, ammo)
	queue_free()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("Weapons")
	if weaponType != "":
		SMG = load(weaponType)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Rotation
	var tween = get_tree().create_tween().set_loops()
	tween.tween_property(self, "rotation", rotation + TAU, ROTATE_SPEED)
	
	# Pickup the gun if in area and pressing right click.
	if Input.is_action_just_pressed('rclick') and inPickupArea and playerRef: 
		playerRef.equipWeapon(SMG, ammo)
		self.queue_free()

# Area for the weapon pickup
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		inPickupArea = true
		playerRef = body

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		inPickupArea = false
