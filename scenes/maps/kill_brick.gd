extends Area3D

var rect: ColorRect
var label: Label
var dying := false

func _ready():
	body_entered.connect(_on_body_entered)

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	rect = ColorRect.new()
	rect.color = Color(0.8, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)

	label = Label.new()
	label.text = "You're allergic to red (so you died)!"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 12)
	label.modulate.a = 0.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(label)

func _on_body_entered(body):
	if not body.is_in_group("player") or dying:
		return
	dying = true
	body.set_physics_process(false)
	Engine.time_scale = 0.3

	var t = create_tween()
	t.set_ignore_time_scale(true)
	t.tween_property(rect, "color:a", 0.6, 0.15)
	t.parallel().tween_property(label, "modulate:a", 1.0, 0.15)
	t.tween_property(rect, "color", Color(0, 0, 0, 1), 0.4)
	t.tween_interval(0.5)
	await t.finished

	body.global_position = Respawn.point
	if "velocity" in body:
		body.velocity = Vector3.ZERO
	Engine.time_scale = 1.0
	body.set_physics_process(true)

	var t2 = create_tween()
	t2.tween_property(rect, "color:a", 0.0, 0.4)
	t2.parallel().tween_property(label, "modulate:a", 0.0, 0.4)
	await t2.finished
	dying = false
