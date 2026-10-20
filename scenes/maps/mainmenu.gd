extends Control

@onready var play_button = $CenterContainer/VBoxContainer/Button

func _ready() -> void:
	play_button.grab_focus()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://World.tscn")

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://World.tscn")

func _on_button_pressed() -> void:
	hide()
	get_tree().change_scene_to_file("res://World.tscn")
