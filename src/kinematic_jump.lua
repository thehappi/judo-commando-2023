
local KinematicJump = Class('KinematicJump')

function KinematicJump:__construct()
    self.x0, self.y0 = 0, 0
    self.x1, self.y1 = 0, 0

    self.dist_x = 0
    self.dist_y = 0

    self.dir_x = 0
    self.dir_y = 0

    self.a = 0
    self.v = 0
    self.t = 0
    self.u = 0
    self.s = 0
end

function KinematicJump:init(x0, y0, x1, y1, max_y, initial_vy)
    self.x0, self.y0 = x0, y0
    self.x1, self.y1 = x1, y1

    self.dist_x = self.x1 - self.x0
    self.dist_y = self.y1 - self.y0

    self.dir_x = self.dist_x < 0 and -1 or 1
    self.dir_y = self.dist_y < 0 and -1 or 1
    -- self.dir_y = y0 > y1 and -1 or 1
    -- print(y0, y1, self.dist_y, self.dir_y)
    --=
    if initial_vy then
        self.v = initial_vy
    else
        self.v = 0
    end
    self.a = Tl.Dim*36 -- acceleration (gravity)
    self.t = nil -- total time
    self.u = nil --
    --=

    if max_y or max_y == 0 then
        self.s = -math.abs(max_y)
    elseif self.dir_y >= 0 then
        self.s = (-2 * Tl.Dim) 
        -- print('dir_y > 0', self.s, max_y)
        -- print('1max_y', self.s)
    else
        -- print('dir_y <= 0')
        self.s = self.dist_y - 1.5 * Tl.Dim
        -- print('2max_y', self.s)
    end
    --=
    self.u = -math.sqrt(self.v^2 - 2*self.a*self.s)
    self.zenith_at = -(self.u - self.v) / self.a
    --=
    local a = 0.5 * self.a
    local b = self.u
    local c = self.y0 - self.y1

    self.t = (-b + math.sqrt(b^2 - 4*a*c)) / (2*a)
end

function KinematicJump:getVel(timer)
    if timer > self.t then
        return 0, 0
    end
    local x = self.dist_x * timer / self.t
    local y = self.u + self.a * timer

    return x, y
end

function KinematicJump:getPos(timer)
    if timer > self.t then
        return self.x1, self.y1
    end
    return
        (self.x0 + self.dist_x * timer / self.t),
        (self.y0 + self.u * timer + 0.5 * self.a * timer^2)
end

function KinematicJump:isDone(timer)
    return timer > self.t
end

function KinematicJump:getProgress(timer)
    return timer / self.t * 100
end

function KinematicJump:getProgressToZenith(timer)
    return timer / self.zenith_at * 100
end

return KinematicJump