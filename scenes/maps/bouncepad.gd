extends Area3D

@export var bounce_strength := 20.0

func _ready():
	monitoring = true
	print("BouncePad ready")

func _physics_process(_delta):
	for body in get_overlapping_bodies():
		if body is CharacterBody3D:
			print("bouncing: ", body.name)
			if body.has_method("bounce"):
				body.bounce(bounce_strength)
			else:
				body.velocity.y = bounce_strength
