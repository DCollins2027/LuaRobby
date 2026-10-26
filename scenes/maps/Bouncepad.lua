local BouncePad = {
	extends = Area3D,
}

function BouncePad:_ready()
	self.bounce_strength = 20.0
	self.monitoring = true
	print("BouncePad ready")
end

function BouncePad:_physics_process(delta)
	local bodies = self:get_overlapping_bodies()
	for i = 1, #bodies do
		local body = bodies[i]
		print("overlapping: ", body.name)
		if body.name == "Player" or body:is_in_group("player") then
			print("bouncing")
			local v = body.velocity
			v.y = self.bounce_strength
			body.velocity = v
		end
	end
end

return BouncePad
