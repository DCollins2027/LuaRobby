local Player = {
	extends = CharacterBody3D,
}

function Player:_ready()
	self.move_speed = 5.0
	self.gravity = 9.8
	self.base_cam = self:get_node("BaseCam")
end

function Player:_physics_process(delta)
	local velocity = self.velocity
	
	-- Gravity
	if not self:is_on_floor() then
		velocity.y = velocity.y - self.gravity * delta
	end

	-- Movement input
	local input = Vector2.ZERO

	if Input:is_action_pressed("move_forward") then
		input.y = input.y - 1
	end

	if Input:is_action_pressed("move_back") then
		input.y = input.y + 1
	end

	if Input:is_action_pressed("move_left") then
		input.x = input.x - 1
	end

	if Input:is_action_pressed("move_right") then
		input.x = input.x + 1
	end

	input = input:normalized()

	-- Camera-relative movement
	local camera_basis = self.base_cam.global_transform.basis

	local forward = -camera_basis.z
	local right = camera_basis.x

	-- Keep movement horizontal
	forward.y = 0
	right.y = 0

	forward = forward:normalized()
	right = right:normalized()

	local direction = right * input.x - forward * input.y

	if input:length() > 0 then
		direction = direction:normalized()

		velocity.x = direction.x * self.move_speed
		velocity.z = direction.z * self.move_speed
	else
		velocity.x = 0
		velocity.z = 0
	end

	self.velocity = velocity
	self:move_and_slide()
end

return Player
