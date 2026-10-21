extends Area3D

var activated := false

func _ready():
	$Message.hide()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		Respawn.point = $RespawnPoint.global_position
		if not activated:
			activated = true
			show_message()

func show_message():
	$Message.show()
	await get_tree().create_timer(2.0).timeout
	$Message.hide()
