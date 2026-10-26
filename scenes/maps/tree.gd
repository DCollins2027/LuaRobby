extends Node3D

func _ready() -> void:
	position.x = -10

	# Brown wooden trunk
	add_block(
		"Trunk",
		Vector3(0, 1.5, 0),
		Vector3(1, 3, 1),
		Color(0.40, 0.22, 0.10)
	)

	# Green blocky leaves
	for y in range(3, 6):
		for x in range(-1, 2):
			for z in range(-1, 2):
				if y == 3 or x == 0 or z == 0 or (x != 0 and z != 0):
					add_block(
						"Leaf",
						Vector3(x, y + 0.5, z),
						Vector3.ONE,
						Color(0.18, 0.55, 0.16)
					)

func add_block(
	block_name: String,
	block_position: Vector3,
	block_size: Vector3,
	block_color: Color
) -> void:
	var body := StaticBody3D.new()
	body.name = block_name
	body.position = block_position
	add_child(body)

	# Visible cube
	var mesh_instance := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = block_size
	mesh_instance.mesh = cube

	var material := StandardMaterial3D.new()
	material.albedo_color = block_color
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	# Matching collision hitbox
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = block_size
	collision.shape = shape
	body.add_child(collision)
