-- local Parabol = require "Parabol"
-- ParabolJump = class('ParabolJump')


-- function ParabolJump:__construct()
-- 	self.pd = Parabol();
-- 	self.pu = Parabol();

-- 	self.w = 0;
-- 	self.h = 0;
-- 	self.vx = 0;
-- 	self.shiftY = 0;
-- end


-- function ParabolJump:init(start, target, shiftX, shiftY)

-- 	self.w = math.abs(target.x - start.x)
-- 	self.h = math.abs(target.y - start.y) + shiftY;

-- 	if (self.w == 0) then
-- 		self.w = 100;
-- 	end

-- 	shiftY = (shiftY == 0 and 50 or shiftY);
-- 	shiftX = (shiftX == 0 or shiftX >= self.w) and self.w * 0.5 or shiftX

-- 	if (start.y < target.y) then
-- 		self.pu:init((self.w - shiftX) * 2, shiftY);
-- 		self.pd:init(shiftX * 2, self.h);
-- 		self.pd:setX(0);

-- 	elseif (start.y > target.y) then
-- 		self.pu:init((self.w - shiftX) * 2, self.h);
-- 		self.pd:init(shiftX * 2, shiftY);
-- 		self.pd:setX(0);
	
-- 	elseif (start.y == target.y) then
	
-- 		self.pu:init((self.w - shiftX) * 2, shiftY);
-- 		self.pd:init(shiftX * 2, shiftY);
-- 		self.pd:setX(0);
-- 	end
-- end


-- function ParabolJump:update( vx )

-- 	local vy = 0;

-- 	vx = math.abs( vx );
-- 	self.vx = vx;
	
-- 	if (self.pu.x + vx <= 0) then
-- 		vy = self.pu:update(vx);
	
-- 		-- elseif (self.pu.x < 0 and self.pu.x + vx > 0) then
-- 		-- 	vy = self.pu:update(0);

-- 	elseif (self.pd.x <= self.pd.w * 0.5) then
-- 		vy = self.pd:update(vx);
	
-- 	end

-- 	return (vy);
-- end


-- function ParabolJump:isFinished()
-- 	return (self.pd:isFinished());
-- end

-- function ParabolJump:isGoingDown()
-- 	-- print(self.pd.x)
-- 	return (self.pd.x > 0);
-- end


-- function ParabolJump:getX()

-- 	if (self.pu.x + self.vx <= 0) then
-- 		return (self.pu.x);
-- 	elseif (self.pd.x <= self.pd.w * 0.5) then
-- 		return (self.pd.x);
-- 	end
-- end

-- -- return ParabolJump
