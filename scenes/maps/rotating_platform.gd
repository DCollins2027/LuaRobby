extends AnimatableBody3D

@export var move_offset := Vector3(15, 0, 0)  # how far it travels from where you place it
@export var move_time := 4.0                  # seconds for one trip
@export var pause_time := 0.5                 # wait at each end

func _ready():
	var start := position
	var end := position + move_offset

	var t = create_tween().set_loops()
	t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)  # keeps the player riding smoothly
	t.tween_interval(pause_time)
	t.tween_property(self, "position", end, move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(pause_time)
	t.tween_property(self, "position", start, move_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
