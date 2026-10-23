local Player = {
	extends = CharacterBody3D,
}

function Player:_ready()
	self.move_speed = 5.0
	self.gravity = 16.0
	self.base_cam = self:get_node("BaseCam")
	self.camera_arm = self.base_cam:get_node("CameraArm")
	self.camera = self.camera_arm:get_node("Camera")
	self.jump_strength = 7.0
	self.light = self:get_node("PlayerLight")
	self.model = self:get_node("Model")
	self.anim = self:get_node("Model/Ninja/AnimationPlayer2")
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
	
	if Input:is_action_pressed("move_jump") then
		if self:is_on_floor() then
			velocity.y = self.jump_strength
		end
	end

	--if Input:is_action_pressed("jump") then
		--input.y = input.y + 1
	--end

	input = input:normalized()

	-- Camera-relative movement
	local camera_basis = self.base_cam.global_transform.basis
	
	-- Light follow Player
	
	local light_transform = self.light.global_transform
	light_transform.basis = self.camera.global_transform.basis
	self.light.global_transform = light_transform

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
		
		local target = math.atan(direction.x, direction.z) + math.pi
		local rot = self.model.rotation
		rot.y = lerp_angle(rot.y, target, 12 * delta)
		self.model.rotation = rot
	else
		velocity.x = 0
		velocity.z = 0
	end

	self.velocity = velocity
	self:move_and_slide()
	
	local wanted = "Idle"

	if not self:is_on_floor() then
		if self.velocity.y > 0 and not self.jump_started then
			self.jump_started = true
			wanted = "Jump"
		elseif self.anim.current_animation == "Jump" and self.anim:is_playing() then
			wanted = "Jump"
		else
			wanted = "Fall"
		end
	else
		self.jump_started = false
		if input:length() > 0 then
			wanted = "Run"
		end
	end

	if self.anim.current_animation ~= wanted then
		self.anim:play(wanted, 0.15)
	end
end
	

return Player
