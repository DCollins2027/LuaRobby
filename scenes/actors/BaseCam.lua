local BaseCam = {
	extends = Node3D,
}

function BaseCam:_ready()
	self.spring_arm = self:get_node("CameraArm")
	self.camera = self.spring_arm:get_node("Camera")

	self.mouse_sensitivity = 0.003
	self.pitch = -10.0
	self.yaw = 0.0

	self.spring_arm.spring_length = 4.0
	self.spring_arm.position = Vector3(0, 1.5, 0)

	self.spring_arm.rotation_degrees = Vector3(self.pitch, 0, 0)
	self.rotation_degrees = Vector3(0, self.yaw, 0)

	self.camera.current = true

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
end

function BaseCam:_unhandled_input(event)
	if event:get_class() == "InputEventMouseMotion" then
		self.yaw = self.yaw - event.relative.x * self.mouse_sensitivity * 180.0 / math.pi
		self.pitch = self.pitch - event.relative.y * self.mouse_sensitivity * 180.0 / math.pi

		self.pitch = math.max(-60.0, math.min(30.0, self.pitch))

		self.rotation_degrees = Vector3(0, self.yaw, 0)
		self.spring_arm.rotation_degrees = Vector3(self.pitch, 0, 0)

	elseif event:is_action_pressed("ui_cancel") then
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	end
end

return BaseCam
