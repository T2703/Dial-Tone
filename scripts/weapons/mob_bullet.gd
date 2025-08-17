extends Area2D

# How long the bullet lasts for
const BULLET_LIFE = 5

# The life of the bullet if we don't have this it will cause issues
@onready var bulletTimer: Timer = $BulletTimer

# The velocity of the bullet from the gun.
@export var velocity: int

# The damage of the bullet from the gun.
@export var damage: int

# Gets the damage of the gun.
func getDamage() -> int:
	return damage
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bulletTimer.wait_time = BULLET_LIFE
	bulletTimer.start()

# Speed/velocity of the bullet.
func _physics_process(delta: float) -> void:
	position += transform.x * velocity * delta

func _on_bullet_timer_timeout() -> void:
	self.queue_free()
