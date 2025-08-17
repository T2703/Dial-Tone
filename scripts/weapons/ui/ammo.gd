extends Label

# Weapon reference
var weaponRef

# The max ammo of the weapon
var weaponRefAmmo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	weaponRef = get_parent().get_parent()
	weaponRefAmmo = weaponRef.ammoText


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if weaponRef.get_parent().get_parent().name == "Player":
		text = str(weaponRef.ammo) + "/" + str(weaponRefAmmo)
	else:
		text = ""
		
