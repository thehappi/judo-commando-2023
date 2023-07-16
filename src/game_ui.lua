local AnimAtlas = AnimAtlas or require 'anim_atlas'
local JewelUi = JewelUi or require 'jewel_ui'

local GameUi = {}

GameUi.new = function()
    local o = {}

    o.font = love.graphics.newFont('asset/font/Pixelation.ttf')
    o.font_score = love.graphics.newImageFont("asset/font/img-1.png",
        " abcdefghijklmnopqrstuvwxyz" ..
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
        "123456789.,!?-+/():;%&`'*#=[]\""
    )
    o.score_text = love.graphics.newText(o.font_score)
    o.level_text = love.graphics.newText(o.font_score)

    o.health_bar = {
        quad = nil,
        x = 2,
        y = 4,
        w = 74,
        h = 12,
    }

    o.health_bar.quad =
        love.graphics.newQuad(110, 0, o.health_bar.w, o.health_bar.h, Spritesheet.Item_And_Fx:getDimensions())
    o.health_pt_quad =
        love.graphics.newQuad(50, 10, 6, 8, Spritesheet.Item_And_Fx:getDimensions())

    o.jewel_ui = JewelUi.new()
    o.jewel_ui:init()

    return setmetatable(o, {__index = GameUi})
end

local __draw_health_bar = function (self)
    local hb_x = self.health_bar.x
    local hb_y = self.health_bar.y
    local sc = GAME.ui_scale

    love.graphics.draw(Spritesheet.Item_And_Fx, self.health_bar.quad, hb_x, hb_y, 0, sc, sc)
    for i=0, GAME.e_hero.c_health.hp-1 do
        love.graphics.draw(Spritesheet.Item_And_Fx, self.health_pt_quad,  hb_x + (6*sc) + i * (6*sc), hb_y+(2*sc), 0, sc, sc)
    end
end

local __print_score = function (self)
    self.score_text:set(string.format("%08d", GAME.score))
    local sc = GAME.ui_scale + 0.5
    local x = love.graphics.getWidth() - (self.score_text:getWidth()*sc) - 2
    local y = love.graphics.getHeight() - (self.score_text:getHeight()*sc) + 4

    love.graphics.draw(self.score_text, x, y, 0, sc, sc)
end

local __print_level = function (self)
    self.level_text:set('LEVEL' .. GAME.level)
    local sc = GAME.ui_scale
    -- local x = (love.graphics.getWidth()*.5) - (self.level_text:getWidth()*sc*.5)
    local x = self.health_bar.x + self.health_bar.w * sc + 20
    local y = self.health_bar.y + self.health_bar.h * sc * .5 - (self.level_text:getHeight()*1.5 * .5)

    love.graphics.draw(self.level_text, x, y, 0, 1.5, 1.5)
end

local __print_perf = function (self)
    love.graphics.setFont(self.font)
    love.graphics.print(
        math.ceil(collectgarbage("count") / 1000) .. 'mb' .. ' - ' ..
        love.timer.getFPS() .. ' fps', 10, 40
    )

    love.graphics.print(GAME.level_enemy_cnt .. 'ens', 10, 60)
end

function GameUi:init()
    self.jewel_ui:init()
end

function GameUi:update(dt)
    self.jewel_ui:update(dt)
end

function GameUi:draw()
    love.graphics.setColor(GAME.draw_color.ui or {1,1,1,1})
    self.jewel_ui:draw()
    __draw_health_bar(self)
    __print_score(self)
    __print_level(self)
    __print_perf(self)
end

return GameUi

