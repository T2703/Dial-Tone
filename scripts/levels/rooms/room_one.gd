extends Node2D

# Items/Weapons to drop.
var itemDrops = {
	"smg": preload("res://scenes/weapons/smg_pickup.tscn"),
	"pistol": preload("res://scenes/weapons/pistol_pickup.tscn"),
	"bat": preload("res://scenes/weapons/bat_pickup.tscn"),
}

# The chance for them to spawn in.
var probablities = {
	"smg": 0.6,
	"pistol": 0.5,
	"bat": 0.6,
}

# Chooses which item to spawn in.
func getRandomItem() -> String:
	# Roll
	var roll = randf()
	var cumulative = 0.0
	var totalWeight = 0.0
	
	# Sum up the weights
	for w in probablities.values():
		totalWeight += w
		
	# Spawn in depending on chance.
	for key in probablities.keys():
		cumulative += probablities[key] / totalWeight
		if roll <= cumulative:
			return key
	return "" 

func _ready():
	# Random rolls
	randomize()
	
	var spawns = get_node("ItemDrops").get_children()
	
	# Go through each marker 2d
	for spawn in spawns:
		var itemName = getRandomItem()
		if itemName != "":
			var item = itemDrops[itemName].instantiate()
			add_child(item)
			item.global_position = spawn.global_position
	
