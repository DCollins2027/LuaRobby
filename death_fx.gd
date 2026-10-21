extends CanvasLayer

var rect: ColorRect
var dying := false

func _ready():
	layer = 100
	rect = ColorRect.new()
	rect.color = Color(0.8, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)

func play(body):
	if dying:
		return
	dying = true
	body.set_physics_process(false)  # freeze the player
	Engine.time_scale = 0.3          # slow motion

	var t = create_tween()
	t.set_ignore_time_scale(true)
	t.tween_property(rect, "color:a", 0.6, 0.15)            # red flash
	t.tween_property(rect, "color", Color(0, 0, 0, 1), 0.4) # fade to black
	await t.finished

	body.global_position = Respawn.point
	if "velocity" in body:
		body.velocity = Vector3.ZERO
	Engine.time_scale = 1.0
	body.set_physics_process(true)

	var t2 = create_tween()
	t2.tween_property(rect, "color:a", 0.0, 0.4)            # fade back in
	await t2.finished
	dying = false
