local GameObject = {}
function GameObject:new()
	local g = {}
	function g:setPosition(_x, _y)
		g.x = _x
		g.y = _y
	end
	
	function g:setCollision(_w, _h)
		g.collision = display.newRect(g.x, g.y, _w, _h)
	end


	function g:translate(_x, _y)
		g.x = g.x+_x
		g.y = g.y+_y
	end

	local function update()
		g.collision.x = g.x
		g.collision.y = g.y
	end
	Runtime:addEventListener("enterFrame", update)
	return g
end
return GameObject