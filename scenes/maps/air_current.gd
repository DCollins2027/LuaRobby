extends Area3D

@export var min_rise := 1.0     # lowest upward speed while inside (keeps them from sinking)
@export var push := 27.0        # how hard it pushes up each second, on top of cancelling gravity

func _physics_process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and "velocity" in body:
			var v = body.velocity
			v.y += push * delta          # steady upward push
			v.y = max(v.y, min_rise)     # never allow downward movement
			body.velocity = v
