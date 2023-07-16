local iga = require "iga"

love.window.setMode(800,600,{borderless = true})

math.randomseed(os.time())

local imgdata = love.image.newImageData("input/input_10.png")


local ow, oh = 100,100

iga:geninit(imgdata, ow,ow, imgdata:getWidth(), imgdata:getHeight(), 3)

love.draw = function()
	love.graphics.scale(8,8)

	for i=1, 20 do
		iga:genstep()
	end
	
	for x=0, ow-1 do
		for y=0,ow-1 do
			local k = iga:getColours()[x+y*ow]
			if k and k > 0 then
				local c = string.format("%09d",tostring(k))
				local r,g,b = string.sub(c,1, 3), string.sub(c,4, 6), string.sub(c,7, 9)
				love.graphics.setColor(tonumber(r)/255,tonumber(g)/255,tonumber(b)/255)
				love.graphics.rectangle("fill",x,y,1,1)
			end
		end
	end
end