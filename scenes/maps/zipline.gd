extends Node3D

@export var speed := 12.0
@export var hang_offset := Vector3(0, -1.8, 0)  # how far below the cable the player hangs
@export var return_time := 2.0  # seconds for the handle to slide back

@onready var start: Marker3D = $Start
@onready var end: Marker3D = $End
@onready var grab_area: Area3D = $GrabArea
@onready var handle: Node3D = get_node_or_null("Handle")

var rider: CharacterBody3D = null
var progress := 0.0
var length := 0.0
var cooldown := 0.0
var handle_tween: Tween
var handle_rest := Vector3.ZERO

func _ready():
	length = start.global_position.distance_to(end.global_position)
	grab_area.body_entered.connect(_on_body_entered)

	# Remember where you placed the handle (doesn't move it)
	if handle:
		handle_rest = handle.global_position

func _on_body_entered(body):
	if rider != null or cooldown > 0.0:
		return
	if body.is_in_group("player"):
		if handle_tween:
			handle_tween.kill()

		rider = body
		progress = 0.0
		rider.set_meta("ziplining", true)
		rider.velocity = Vector3.ZERO

		# Face the model down the cable
		var dir = (end.global_position - start.global_position).normalized()
		rider.get_node("Model").rotation.y = atan2(dir.x, dir.z) + PI

func _physics_process(delta):
	if cooldown > 0.0:
		cooldown -= delta

	if rider == null:
		return

	# Hop off with jump
	if Input.is_action_just_pressed("move_jump"):
		_release(true)
		return

	progress += speed * delta
	var t = clamp(progress / length, 0.0, 1.0)

	var cable_point = start.global_position.lerp(end.global_position, t)
	if handle:
		# Follow along the cable horizontally, keep the placed height
		handle.global_position = Vector3(cable_point.x, handle_rest.y, cable_point.z)
	rider.global_position = cable_point + hang_offset

	if t >= 1.0:
		_release(false)

func _release(jumped: bool):
	var dir = (end.global_position - start.global_position).normalized()
	rider.set_meta("ziplining", false)
	rider.velocity = dir * speed + (Vector3.UP * 6.0 if jumped else Vector3.ZERO)
	rider = null
	cooldown = return_time  # can't regrab until the handle is back

	# Slide the handle back to where you placed it
	if handle:
		if handle_tween:
			handle_tween.kill()
		handle_tween = create_tween()
		handle_tween.tween_property(handle, "global_position", handle_rest, return_time)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
