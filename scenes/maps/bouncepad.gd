local BouncePad = {
	extends = Area3D,
}

function BouncePad:_ready()
	self.bounce_strength = 14.0
	print("BouncePad ready")
	self.body_entered:connect(function(body)
		print("entered by: ", body.name)
		if body:is_in_group("player") then
			print("player detected, bouncing")
			local v = body.velocity
			v.y = self.bounce_strength
			body.velocity = v
		end
	end)
end

return BouncePad
