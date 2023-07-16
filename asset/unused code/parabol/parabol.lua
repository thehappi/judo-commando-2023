local Parabol = class('Parabol')


function Parabol:__construct()
	self.a = 0
	self.x, self.y = 0, 0
	self.w, self.h = 0, 0
end


function Parabol:init( w, h )
	self.w = w;
	self.h = h;

	self.x = -(self.w*0.5);

	self.a = self.h / (self.x * self.x);
	self.y = self.a * (self.x * self.x) + self.h;
end


function Parabol:update( vx )

	local 	vy = 0;
	
	if (self.x < self.w * 0.5) then
	
		if (self.x + vx >= 0 and self.x < 0) then
			self.x = 0;

		elseif (self.x + vx > self.w * 0.5) then
			self.x = self.w * 0.5;
		
		else
			self.x = self.x + vx;
		end

		
		vy = self.a * (self.x * self.x) + self.h - self.y;
		self.y = self.a * (self.x * self.x) + self.h;	
	end

	return (vy);
end


function Parabol:setX( x )
	self.x = x;
	self.y =  self.a * (self.x * self.x) + self.h;
end


function Parabol:isFinished()
	
	if ( self.x >= self.w * 0.5 ) then
		return true;
	end
	return false;
end


return Parabol

