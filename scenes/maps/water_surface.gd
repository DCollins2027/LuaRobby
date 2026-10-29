class_name Water_Surface
extends MeshInstance3D
## Attach to the MeshInstance3D that holds your water.
## - Sets up the plane mesh, the shader material and a generated normal map
## - Feeds time and ripples to the shader
## - Detects bodies hitting the water (ripples, wakes, splashes)
## - get_height_at() gives the wave height on the CPU (for floating objects)

const MAX_RIPPLES := 8

@export_group("Setup")
## Assign water.gdshader here (or set a ShaderMaterial as Material Override yourself).
@export var shader: Shader
@export var configure_plane := true
@export var plane_size := Vector2(100.0, 100.0)
@export var plane_subdivisions := 200
@export var generate_normal_map := true

@export_group("Waves (pushed to the shader)")
## x,y = direction, z = steepness, w = wavelength in meters
@export var wave_a := Vector4(1.0, 0.2, 0.20, 12.0)
@export var wave_b := Vector4(0.6, 1.0, 0.16, 7.0)
@export var wave_c := Vector4(-0.7, 0.5, 0.10, 3.5)
@export var wave_d := Vector4(0.3, -1.0, 0.07, 2.0)
@export var wave_strength := 0.6
@export var wave_speed := 0.7
## Re-sends the wave settings every frame so you can tweak them while the game runs.
@export var live_update := false

@export_group("Interaction")
@export var detect_bodies := true
@export_flags_3d_physics var detection_mask := 1
## Half-height of the detection volume around the water surface.
@export var water_thickness := 1.0
@export var wake_ripples := true
@export var wake_interval := 0.2
@export var min_wake_speed := 1.0
@export var splash_particles := true
@export var splash_color := Color(0.85, 0.95, 1.0, 0.8)

var _material: ShaderMaterial
var _time := 0.0
var _ripples: Array = []
var _next_ripple := 0
var _bodies := {}  # body -> next wake time
var _area: Area3D


func _ready() -> void:
	_setup_mesh()
	if not _setup_material():
		set_process(false)
		return
	if generate_normal_map:
		_material.set_shader_parameter("normal_map", _make_normal_map())

	for i in MAX_RIPPLES:
		_ripples.append(Vector4.ZERO)
	_material.set_shader_parameter("impacts", _ripples.duplicate())

	_apply_settings()
	if detect_bodies:
		_setup_detector()


func _process(delta: float) -> void:
	_time += delta
	_material.set_shader_parameter("water_time", _time)
	if live_update:
		_apply_settings()
	if wake_ripples:
		_update_wakes()


# ------------------------------------------------------------------ public API

## Spawns a ripple ring at a world position. strength ~0.3 (gentle) to 2.0 (big).
func add_ripple(world_pos: Vector3, strength := 1.0) -> void:
	if _material == null:
		return
	_ripples[_next_ripple] = Vector4(world_pos.x, world_pos.z, _time, strength)
	_next_ripple = (_next_ripple + 1) % MAX_RIPPLES
	_material.set_shader_parameter("impacts", _ripples.duplicate())


## Ripple + splash particles. Call this from your KillZone if you like.
func impact(world_pos: Vector3, strength := 1.0) -> void:
	var pos := Vector3(world_pos.x, get_height_at(world_pos), world_pos.z)
	add_ripple(pos, strength)
	if splash_particles:
		_spawn_splash(pos, strength)


## Approximate wave height (world Y) at a world position. Matches the shader waves.
func get_height_at(world_pos: Vector3) -> float:
	var p := Vector2(world_pos.x, world_pos.z)
	var q := p
	# Gerstner waves also move vertices sideways, so find the source point.
	for i in 3:
		var d := _gerstner(q)
		q = p - Vector2(d.x, d.z)
	return global_position.y + _gerstner(q).y


# ------------------------------------------------------------------ setup

func _setup_mesh() -> void:
	if configure_plane:
		var pm := mesh as PlaneMesh
		if pm == null:
			pm = PlaneMesh.new()
			mesh = pm
		pm.size = plane_size
		pm.subdivide_width = plane_subdivisions
		pm.subdivide_depth = plane_subdivisions
	# Waves move vertices outside the original bounds, so avoid culling pop-in.
	extra_cull_margin = 10.0
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _setup_material() -> bool:
	_material = material_override as ShaderMaterial
	if _material == null:
		if shader == null:
			push_warning("WaterSurface: assign water.gdshader to the 'shader' property.")
			return false
		_material = ShaderMaterial.new()
		_material.shader = shader
		material_override = _material
	return true


func _make_normal_map() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.fractal_octaves = 4
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	tex.as_normal_map = true
	tex.bump_strength = 6.0
	tex.noise = noise
	return tex


func _apply_settings() -> void:
	_material.set_shader_parameter("wave_a", wave_a)
	_material.set_shader_parameter("wave_b", wave_b)
	_material.set_shader_parameter("wave_c", wave_c)
	_material.set_shader_parameter("wave_d", wave_d)
	_material.set_shader_parameter("wave_strength", wave_strength)
	_material.set_shader_parameter("wave_speed", wave_speed)


func _setup_detector() -> void:
	var size := plane_size
	if mesh is PlaneMesh:
		size = (mesh as PlaneMesh).size

	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = detection_mask
	_area.monitoring = true

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, water_thickness * 2.0, size.y)
	shape.shape = box
	_area.add_child(shape)
	add_child(_area)

	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)


# ------------------------------------------------------------------ interaction

func _on_body_entered(body: Node3D) -> void:
	_bodies[body] = _time + wake_interval
	var vel := _get_body_velocity(body)
	var strength := clampf(0.4 + absf(vel.y) / 8.0, 0.4, 2.0)
	impact(body.global_position, strength)


func _on_body_exited(body: Node3D) -> void:
	_bodies.erase(body)


func _update_wakes() -> void:
	for key in _bodies.keys():
		if not is_instance_valid(key):
			_bodies.erase(key)
			continue
		if _time < _bodies[key]:
			continue
		var body: Node3D = key
		var vel := _get_body_velocity(body)
		var speed := Vector2(vel.x, vel.z).length()
		if speed >= min_wake_speed:
			add_ripple(body.global_position, clampf(speed / 6.0, 0.2, 0.8))
			_bodies[key] = _time + wake_interval


func _get_body_velocity(body: Node3D) -> Vector3:
	if body is CharacterBody3D:
		return (body as CharacterBody3D).velocity
	if body is RigidBody3D:
		return (body as RigidBody3D).linear_velocity
	return Vector3.ZERO


func _spawn_splash(pos: Vector3, strength: float) -> void:
	var p := CPUParticles3D.new()
	p.top_level = true
	p.one_shot = true
	p.emitting = false
	p.amount = int(20.0 + 30.0 * clampf(strength, 0.0, 2.0))
	p.lifetime = 0.9
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 35.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 2.0 + 3.0 * strength
	p.gravity = Vector3(0.0, -9.8, 0.0)

	var drop := SphereMesh.new()
	drop.radius = 0.04
	drop.height = 0.08
	drop.radial_segments = 6
	drop.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = splash_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop.material = mat
	p.mesh = drop

	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.5).timeout.connect(p.queue_free)


# ------------------------------------------------------------------ CPU waves

func _gerstner(p: Vector2) -> Vector3:
	var out := Vector3.ZERO
	for w in [wave_a, wave_b, wave_c, wave_d]:
		var wv: Vector4 = w
		var steep := wv.z * wave_strength
		var k := TAU / wv.w
		var c := sqrt(9.8 / k) * wave_speed
		var d := Vector2(wv.x, wv.y).normalized()
		var f := k * (d.dot(p) - c * _time)
		var a := steep / k
		out += Vector3(d.x * a * cos(f), a * sin(f), d.y * a * cos(f))
	return out
