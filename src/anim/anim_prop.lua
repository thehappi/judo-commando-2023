local AnimFrame = AnimFrame or require 'anim.anim_frame'

local AnimProp = Class('AnimProp')

function AnimProp:__construct(spritesheet)
    self.spritesheet=spritesheet
    self.frames_uniq={}
    self.frames={}
    self.quads = {}
    self.duration=0
    self.frame_w=0
    self.frame_h=0
    self.__pause=false
    self.__loop=false
    return self
end

function AnimProp:contiguous(v2_offset, v2_frame_size, frame_count, duration_ms)
    --
    self.duration=duration_ms/1000
    self.frame_w = v2_frame_size.x
    self.frame_h =  v2_frame_size.y
    -- self.offset_x = v2_offset.x
    -- self.offset_y = v2_offset.y

    for i=1, frame_count do
        local frame_x = v2_offset.x + (i-1) * self.frame_w
        local frame_y = v2_offset.y
		local quad = love.graphics.newQuad(
            frame_x,
            frame_y,
            self.frame_w,
            self.frame_h,
            self.spritesheet:getDimensions()
        )
        self.frames[i] = AnimFrame(i, quad, self.frame_w, self.frame_h)
        table.insert(self.quads, quad)
	end
    return self
end

function AnimProp:loop()
    self.__loop=true
    return self
end


function AnimProp:dup(frame_i, n)
    n = n or 1
    for i=1, #self.frames do
        if self.frames[i].i == frame_i then
            local frame_cpy = self.frames[i]
            for j=1, n do
                table.insert(self.frames, i+1, frame_cpy)
            end
            break
        end
    end
    return self
end

function AnimProp:dupAll(n)
    local cnt = #self.frames
    n = n or 1
    for i=1, cnt do
        self:dup(self.frames[i].i, n)
    end
    return self
end

function AnimProp:origin_x(ox)
    for i=1, #self.frames do
        self.frames[i].ox = ox
    end
    return self
end

function AnimProp:origin_y(oy)
    for i=1, #self.frames do
        self.frames[i].oy = oy
    end
    return self
end

function AnimProp:pause()
    self.__pause = true
end

return AnimProp