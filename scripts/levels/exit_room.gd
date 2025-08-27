extends Node2D

# The scene of the loading screen.
var loadingScreenScene = preload("res://scenes/levels/loading_screen.tscn")

# Progress to the next level.
func _on_exit_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Save stats
		body.saveState()

		# Remove player from old scene so it won't get freed
		body.get_parent().remove_child(body)
		
		# Show the loading screen.
		var loadingScreen = loadingScreenScene.instantiate()
		get_tree().root.add_child(loadingScreen)
		
		# Render.
		await get_tree().process_frame
		
		# Async load.
		ResourceLoader.load_threaded_request("res://scenes/levels/main_level.tscn")
		
		# Poll until finished.
		while true:
			var progress = []
			var status = ResourceLoader.load_threaded_get_status("res://scenes/levels/main_level.tscn", progress)
			print("LOADING")
			
			# End loop once loaded.
			if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
				break
			await get_tree().process_frame

		# Load new level
		var nextLevelPacked = ResourceLoader.load_threaded_get("res://scenes/levels/main_level.tscn")
		get_tree().call_deferred("change_scene_to_packed", nextLevelPacked)

		# Wait until scene is changed, then reattach player
		await get_tree().tree_changed
		
		loadingScreen.queue_free()
		
		# Go to the next level.
		var nextLevel = get_tree().current_scene
		nextLevel.add_child(body)
		body.global_position = nextLevel.get_node("PlayerSpawn").global_position
