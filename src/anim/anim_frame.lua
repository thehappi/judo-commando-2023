local AnimFrame = Class('AnimFrame')

function AnimFrame:__construct(i, quad, w, h)
    self.i = i
    self.quad=quad
    self.w=w
    self.h=h
    self.ox=.5
end

return AnimFrame