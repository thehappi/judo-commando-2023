local JewelUi = {}

JewelUi.new = function()
    local o = {}
    o.anim = {
        play = false,
        timer = 0,
        timeout = 0,
        index = 1,
        rollin_timeout = 2,
        rollin_interval = 0.015,
    }
    return setmetatable(o, {__index = JewelUi})
end

--===========================#
-- = PRIVATE METHODS
--==#

local __startRollAnim = function(self)
    self.anim.play = true
    self.anim.timer = 0
    self.anim.index = 1
    self.anim.timeout = 0
end

--====#

local __stopRollAnim = function(self)
    self.anim.play = false
end

--====#

local __updateRollAnim = function (self)
    local anim = self.anim

    if anim.play then
        local order = self.jwl_collec_order
        local dt = love.timer.getDelta()

        anim.timer = anim.timer + dt
        anim.timeout = anim.timeout + dt

        if anim.timer > anim.rollin_interval then
            anim.timer = anim.rollin_interval - anim.timer
            anim.index = anim.index + 1
            -- print(math.sin(anim.index ))
        end
        if anim.index > #order then
            anim.index = 1--math.random(1, #order)
        end
        if anim.timeout > anim.rollin_timeout then
            __stopRollAnim(self)
            GameSignal:jewelSetComplete()
        end
    end
end

--====#

local __drawRollAnim = function(self)
    local anim = self.anim

    if anim.play then
        local draw_x = love.graphics.getWidth() - 2 - 8 * (18 * GAME.world.sc)
        local draw_y = 4
        local order = self.jwl_collec_order

        for i, jwl in ipairs(order) do
            if jwl ~= E_Jewel.Color.Nil then
                
                local j = (i + anim.index) % #order + 1
                local color = order[j]
                local data = self.jwl_collec[color]
                local w = data.w
                local x = draw_x + w*GAME.world.sc*(i-2)
                local t = anim.rollin_timeout - anim.timeout
    
                if anim.timeout > 1.8 then-- and i > math.ceil(t * 10 * 4) then
                    local quad = self.jwl_collec['nil'].quad
                    love.graphics.draw(Spritesheet.Item_And_Fx, quad, x, draw_y, 0, GAME.world.sc, GAME.world.sc)
                else
                    love.graphics.draw(Spritesheet.Item_And_Fx, data.quad, x, draw_y, 0, GAME.world.sc, GAME.world.sc)
                end
            end
        end
    end
end

--====#

local __drawCollection = function(self)
    local C = E_Jewel.Color
    local order = {C.Red, C.Orange, C.Yellow, C.Green, C.Cyan, C.Blue, C.Purple, C.Pink}
    local sc = GAME.ui_scale
    local draw_x = love.graphics.getWidth() - 2 - 8 * (18 * sc)
    local draw_y = 4

    for i, color_key in ipairs(order) do
        local data = self.jwl_collec[color_key]
        local w = data.w
        local x = draw_x + w*sc*(i-1)
        
        if data.gathered then
            local quad = data.quad
            love.graphics.draw(Spritesheet.Item_And_Fx, quad, x, draw_y, 0, sc, sc)
        else
            local quad = self.jwl_collec['nil'].quad
            love.graphics.draw(Spritesheet.Item_And_Fx, quad, x, draw_y, 0, sc, sc)
        end
    end
end

--====#

local __reset = function(self)
    for _, jwl_data in pairs(self.jwl_collec) do
        jwl_data.gathered=false
    end
end

--====#

local __isCollecCompleted = function(self)
    for color_k, jwl_data in pairs(self.jwl_collec) do
        if color_k ~= 'nil' and not jwl_data.gathered then
            return false
        end
    end
    return true
end

--===========================# 
-- = PUBLIC METHODS
--==#

function JewelUi:init()
    local JC = E_Jewel.Color
    self.jwl_collec = {}
    self.jwl_collec_order = {JC.Nil, JC.Red, JC.Orange, JC.Yellow, JC.Green, JC.Cyan, JC.Blue, JC.Purple, JC.Pink}
    for i, k in ipairs(self.jwl_collec_order) do
        local w = 18
        local h = 14
        local quad_y = 20 + (i-1) * h
        local quad = love.graphics.newQuad(0, quad_y, w, h, Spritesheet.Item_And_Fx:getDimensions())
        self.jwl_collec[k] = {
            gathered=false, quad=quad, w=w, h=h, i
        }
    end
    self.jwl_collec[JC.Red].gathered = false
end

--====#

function JewelUi:update(dt)
    if self.anim and self.anim.play then
        __updateRollAnim(self)
    end
end

--====#

function JewelUi:draw()
    if self.anim and self.anim.play then
        __drawRollAnim(self)
    else
        __drawCollection(self)
    end
end

--====#

function JewelUi:onJewelGathered(color_key)
    self.jwl_collec[color_key].gathered = true
    if __isCollecCompleted(self) then
        __startRollAnim(self)
        __reset(self)
    end
end

return JewelUi

