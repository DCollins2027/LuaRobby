extends Node3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
# Called when the node enters the scene tree for the first time.
