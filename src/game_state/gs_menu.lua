local Tiny = Tiny or require 'lib.tiny'
local UI_Button = UI_Button or require 'ui_button'

local moonshine = moonshine or require 'moonshine.init'

--============= MAIN MENU STATE ==============#

local GS_MainMenu = Class('GS_MainMenu', GameStateInterface)

function GS_MainMenu:__construct()
    local screen_h = love.graphics.getHeight()
    local screen_w = love.graphics.getWidth()
    local button_layout_h = screen_h * 0.7
    self.buttons_enabled = true

    local button_margin_bot = 16

    self.image = {}
    self.image.background = love.graphics.newImage('asset/image/menu-background.png')
    self.image.logo = love.graphics.newImage('asset/image/menu-logo.png')

    self.logo = {}
    self.logo.scale = screen_w / self.image.logo:getWidth() * 0.5
    self.logo.x = screen_w * 0.5 - self.image.logo:getWidth() * self.logo.scale * 0.5
    self.logo.y = 32
    self.logo.color = {1, 0.9, 0, 1} -- {1, 0.6, 0, 1}

    self.buttons = {}
    self.buttons[1] = UI_Button.newGameBtn()
    self.buttons[2] = UI_Button.scoreboardBtn()
    self.buttons[3] = UI_Button('training', function()
        -- GAME_STATE_MACHINE:push(GS_Training():load())
    end, FONT.MAIN_MENU)
    self.buttons[4] = UI_Button.settingsBtn()

    -- = set buttons height
    local button_layout_y = screen_h - button_layout_h
    local button_h = (button_layout_h - button_margin_bot * (#self.buttons)) / #self.buttons 
    
    if button_h > 30 then
        button_h = 30
    end
    
    for i, button in pairs(self.buttons) do
        button.w = 200
        button.h = button_h
        button.x = love.graphics.getWidth() * 0.5 - button.w * 0.5
        button.y = button_layout_y + (button_h + button_margin_bot) * (i - 1)
    end

    -- = EXIT BUTTON
    self.exit_button = UI_Button.exitBtn()
    self.exit_button.w = 75
    self.exit_button.h = 30
    self.exit_button.x = love.graphics.getWidth() - self.exit_button.w - 10
    self.exit_button.y = 10-- self.logo.y + self.image.logo:getHeight() * self.logo.scale * 0.5 - self.exit_button.h * 0.5

    -- = GRADIENT BACKGROUND
    self.gradient = GRADIENT.MAIN_MENU

    -- = STARS
    self.star = {}
    self.star.count = 80
    self.star.max_y = love.graphics.getHeight() * 0.9
    self.star.list = {}
    for i = 1, self.star.count do
        self.star.list[i] = {}
        self.star.list[i].x = love.math.random(0, love.graphics.getWidth())
        self.star.list[i].y = love.math.random(0, self.star.max_y * 0.6)
        --= size of star depends on distance from screen bottom
        self.star.list[i].size = math.random(1, 3) * (1 - self.star.list[i].y / self.star.max_y)
        if  self.star.list[i].size < 1 then
            self.star.list[i].size = 1
        end
        --= glowing of star depends on distance from screen bottom
        local glow = (1 - self.star.list[i].y / self.star.max_y)
        self.star.list[i].color = {1 * glow, 1 * glow, love.math.random(0.6, 1) , glow}
        self.star.list[i].glow = glow
        self.star.list[i].glow_speed = 0.2+math.random(0, 1) * glow
    end

    -- = BACKGROUND
    self.background = {}
    -- = scale so that background fits screen width
    self.background.scale = screen_w / self.image.background:getWidth()
    self.background.x = 0
    self.background.y = screen_h - self.image.background:getHeight() * self.background.scale + 24 * self.background.scale


    -- = SOME CHARACTER ANIMATION
    self.tiny_world = Tiny.world(
        S_StateMachineUpdate,
        S_StateMachineSetNewState,
        S_Animate,
        S_Animate_Hero_Atlas,
        S_Animate_Enemy_Atlas
    )
    self.e_monkey = E_Monkey()
    self.e_monkey.c_anim:set('menu-idle')
    self.e_monkey.c_anim.dir = -1
    self.e_monkey.c_anim.color = {1, 1, 1, 1}
    self.e_monkey.c_anim.props.duration = 1.8
    self.e_monkey.c_b.x = self.logo.x + self.image.logo:getWidth() * self.logo.scale * 0.955
    self.e_monkey.c_b.y = self.logo.y - self.e_monkey.c_b.h 
    self.tiny_world:addEntity(self.e_monkey)

    self.e_hero = E_Hero()
    self.e_hero.c_anim:set('duck')
    self.e_hero.c_anim:set_frame(3)
    self.e_hero.c_anim.dir = 1

    self.e_hero.c_b.x = self.logo.x + self.image.logo:getWidth() * self.logo.scale * 0.355 --* 0.165
    self.e_hero.c_b.y = self.logo.y - self.e_monkey.c_b.h + 2
    self.tiny_world:addEntity(self.e_hero)


    self.e_shuriken = E_Shuriken(nil,nil,1,0,self.e_hero)
    self.e_shuriken.c_anim:set('bullet')
    self.e_shuriken.c_anim.props.duration = 0.75
    self.e_shuriken.c_b.x = self.logo.x + self.image.logo:getWidth() * self.logo.scale * 0.05
    self.e_shuriken.c_b.y = self.logo.y - self.e_shuriken.c_b.h - 1
    self.e_shuriken.c_anim.scale_x = 4
    self.e_shuriken.c_anim.scale_y = 3
    self.tiny_world:addEntity(self.e_shuriken)

    self.e_shuriken2 = E_Shuriken(nil,nil,1,0,self.e_hero)
    self.e_shuriken2.c_anim:set('bullet')
    self.e_shuriken2.c_anim.props.duration = 0.75
    self.e_shuriken2.c_b.x = self.logo.x + self.image.logo:getWidth() * self.logo.scale * 0.255-- 0.37
    self.e_shuriken2.c_b.y = self.logo.y + -self.e_shuriken2.c_b.h - 1
    -- self.e_shuriken2.c_b.y = self.logo.y + self.image.logo:getHeight() * self.logo.scale +6--self.e_shuriken2.c_b.h - 1
    self.e_shuriken2.c_anim.scale_x = 2.5
    self.e_shuriken2.c_anim.scale_y = 3
    self.tiny_world:addEntity(self.e_shuriken2)

    

    self.e_enemies = {}
    self:addEnemyPassingBy(-20, 1)
    
    -- self.e_shuriken3 = E_Shuriken(nil,nil,1,0,self.e_hero)
    -- self.e_shuriken3.c_anim:set('bullet')
    -- self.e_shuriken3.c_anim.props.duration = 0.6
    -- self.e_shuriken3.c_b.x = self.logo.x + self.image.logo:getWidth() * self.logo.scale * 0.64
    -- self.e_shuriken3.c_b.y = self.logo.y - self.e_shuriken3.c_b.h - 1
    -- self.e_shuriken3.c_anim.scale_x = 4
    -- self.e_shuriken3.c_anim.scale_y = 3
    -- self.tiny_world:addEntity(self.e_shuriken3)

    -- = screen shader
    self.effect = moonshine(moonshine.effects.scanlines)
    self.effect.scanlines.width = IS_MOBILE and 3 or 1
    self.effect.scanlines.opacity = IS_MOBILE and 1 or 0.2
        -- .chain(moonshine.effects.glow)
        -- .chain(moonshine.effects.vignette)
        -- .chain(moonshine.effects.godsray)
    -- self.effect.scanlines.width = IS_MOBILE and 3 or 1
    -- self.effect.scanlines.opacity = 0.5
    -- self.effect.glow.min_luma = 0
    -- self.effect.glow.strength = 30
    -- self.effect.godsray.exposure = 0.1

    -- self.star_shader = moonshine(moonshine.effects.glow).chain(moonshine.effects.godsray)
    -- self.star_shader.glow.min_luma = 0
    -- self.star_shader.glow.strength = 20
    -- self.star_shader.godsray.exposure = 0.1
    -- self.effect.scanlines.frequency =
    
    self.logo.shader = moonshine((moonshine.effects.glow))
    self.logo.shader.glow.min_luma = 0
    self.logo.shader.glow.strength = 10

end

function GS_MainMenu:addEnemyPassingBy(x, dir_x)
    if #self.e_enemies > 20 then
        return
    end
    local e_en = E_Enemy()
    if #self.e_enemies == 0 then
        e_en = E_GunSoldier()
    else 
        local rand = math.random(1, 4)
        if rand <= 2  then
            e_en = E_BaseSoldier()
        elseif rand <= 3 then
            e_en = E_RocketSoldier()
        elseif rand <= 4 then
            e_en = E_BombSoldier()
        end
    end
    e_en.c_anim:set('walk')
    e_en.c_anim.dir = dir_x
    e_en.c_anim.props.duration = 0.85
    e_en.c_anim.color = {0, 0, 0, 1}
    e_en.c_b.x = x
    e_en.c_b.y = love.graphics.getHeight() -51
    self.tiny_world:addEntity(e_en)
    table.insert(self.e_enemies, e_en)
end

function GS_MainMenu:load()
    return self
end

function GS_MainMenu:update(dt)
    if self.buttons_enabled then
        for _, button in pairs(self.buttons) do
            button:update()
        end
        self.exit_button:update()
    end
    --= stars glow
    for _, star in pairs(self.star.list) do
        star.glow = star.glow + star.glow_speed * dt
        local sin = 0.3 + math.abs(math.sin(star.glow))
        star.color[4] = sin
    end
    --= enemies passing by
    local walk_speed = 24
    for i, e_en in ipairs(self.e_enemies) do
        e_en.c_b.x = e_en.c_b.x + e_en.c_anim.dir * walk_speed * dt
        
        local rside_turn = (e_en.c_b.x > love.graphics.getWidth() + 20) and (e_en.c_anim.dir == 1)
        local lside_turn = (e_en.c_b.x < -20) and (e_en.c_anim.dir == -1)
        if rside_turn or lside_turn then
            e_en.c_anim.dir = -e_en.c_anim.dir
        end
        if i == #self.e_enemies and rside_turn then
            self:addEnemyPassingBy(e_en.c_b.x + love.math.random(25, 45), e_en.c_anim.dir)
        end
        if i == #self.e_enemies and lside_turn then
            self:addEnemyPassingBy(e_en.c_b.x - love.math.random(25, 45), e_en.c_anim.dir)
        end
    end
    -- self.e_enemy.c_b.x = self.e_enemy.c_b.x + self.e_enemy.c_anim.dir * 24 * dt
    
    -- if
    --     (self.e_enemy.c_b.x > love.graphics.getWidth() + 20)
    --     or (self.e_enemy.c_b.x < -20)
    -- then
    --     self.e_enemy.c_anim.dir = -self.e_enemy.c_anim.dir
    -- end
    --= some character animation
    -- S_StateMachineUpdate:update(dt)
    -- S_StateMachineSetNewState:update(dt)
    -- S_Animate_Hero_Atlas:update(dt)
    -- S_Animate_Enemy_Atlas:update(dt)
    -- if self.e_monkey.c_anim.is_over then
    --     self.e_monkey.c_anim:pause()
    -- end
    self.tiny_world:update()
end

function GS_MainMenu:draw()

    -- love.graphics.setColor(0.5, 0.4, 0.2, 1)
    self.effect(function()
        love.graphics.draw(self.gradient, 0, 0, 0, love.graphics.getDimensions())
    end)
    --= stars
    for _, star in pairs(self.star.list) do
        love.graphics.setColor(star.color)
        love.graphics.circle('fill', star.x, star.y, star.size)
    end
    --= city background
    love.graphics.setColor(0.2, 0.2, 0.1, 1)
    love.graphics.draw(self.image.background, self.background.x, self.background.y, 0, self.background.scale, self.background.scale)
    -- 0, 34+love.graphics.getHeight() - self.image.background:getHeight() * 1.5, 0, 1.4, 1.4)
    -- = logo
    love.graphics.setColor(self.logo.color)
    love.graphics.draw(self.image.logo, self.logo.x, self.logo.y, 0, self.logo.scale, self.logo.scale)

    -- self.logo.shader(function()
    love.graphics.setColor(self.logo.color)
    love.graphics.draw(self.image.logo, self.logo.x, self.logo.y, 0, self.logo.scale, self.logo.scale)
        
    -- end)
    --= buttons
    if self.buttons_enabled then
        love.graphics.setColor(self.logo.color)
        for _, button in pairs(self.buttons) do
            button:draw()
        end
        self.exit_button:draw()
    end
-- self.logo.shader(function()
            -- love.graphics.setColor(1, 1, 1)
        -- end)
        -- love.graphics.setColor(self.logo.color)
        -- love.graphics.draw(self.image.logo, self.logo.x, self.logo.y, 0, self.logo.scale, self.logo.scale)
        -- = some character animation
        S_Animate:update(love.timer.getDelta())
        -- = some shaders
            -- love.graphics.rectangle("fill", 300,200, 200,200)
        -- end) 
        -- self.star_shader(function()
        --     love.graphics.setColor(1, 1, 1, 1)
            
    -- end)
end

function GS_MainMenu:keypressed(k)
    if k == 'escape' then
        love.event.quit()
    end
end

function GS_MainMenu:mousepressed(x, y, button)
    for _, button in pairs(self.buttons) do
        button:mousepressed(x, y)
    end
    self.exit_button:mousepressed(x, y)
end


function GS_MainMenu:exit()
    Tiny.clearSystems(self.tiny_world)
    Tiny.clearEntities(self.tiny_world)
    Tiny.refresh(self.tiny_world)
    collectgarbage("collect")
end

return GS_MainMenu