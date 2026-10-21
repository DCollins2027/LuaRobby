extends Control

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_start_game()
	elif event.is_action_pressed("ui_cancel"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_button_pressed() -> void:
	_start_game()

func _start_game() -> void:
	print("PLAY PRESSED")
	print(ResourceLoader.exists("res://scenes/maps/world.tscn"))
	get_tree().change_scene_to_file("res://scenes/maps/world.tscn")
