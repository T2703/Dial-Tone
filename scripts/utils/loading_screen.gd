extends Node2D

# The loading screen bar.
@onready var bar: ProgressBar = $ProgressBar

func setProgress(value: float) -> void:
	bar.value = value * 100.0 
