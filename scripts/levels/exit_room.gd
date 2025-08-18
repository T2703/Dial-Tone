extends Node2D

# Progress to the next level.
func _on_exit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Save stats
		body.saveState()

		# Remove player from old scene so it won't get freed
		body.get_parent().remove_child(body)

		# Load new level
		var nextLevelPacked = load("res://scenes/levels/main_level.tscn")
		get_tree().call_deferred("change_scene_to_packed", nextLevelPacked)

		# Wait until scene is changed, then reattach player
		await get_tree().tree_changed
		
		# Go to the next level.
		var nextLevel = get_tree().current_scene
		nextLevel.add_child(body)
		body.global_position = nextLevel.get_node("PlayerSpawn").global_position
