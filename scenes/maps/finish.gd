extends Area3D

var finished := false
var rect: ColorRect
var label: Label

func _ready():
	Respawn.start_ms = Time.get_ticks_msec()   # timer starts when the level loads
	body_entered.connect(_on_body_entered)

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0.7)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = false
	layer.add_child(rect)

	label = Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 12)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	layer.add_child(label)

func _on_body_entered(body):
	if finished or not body.is_in_group("player"):
		return
	finished = true
	var elapsed := (Time.get_ticks_msec() - Respawn.start_ms) / 1000.0
	body.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	label.text = "You finished!\nTime: %s\n\nPress R to play again" % _format_time(elapsed)
	rect.visible = true
	label.visible = true

func _unhandled_input(event):
	if finished and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		Respawn.point = Vector3(0, 2, 0)
		Respawn.deaths = 0
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()

func _format_time(t: float) -> String:
	var minutes := int(t / 60.0)
	var seconds := fmod(t, 60.0)
	return "%d:%06.3f" % [minutes, seconds]
