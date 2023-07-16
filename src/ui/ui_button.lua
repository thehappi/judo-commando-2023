local GS_Scoreboard
local GS_Game
local GS_MainMenu

local UI_Button = Class("UI_Button")

function UI_Button:__construct(text, callback, font)
    GS_Scoreboard = GS_Scoreboard or require 'gs_scoreboard'
    GS_Game = GS_Game or require 'gs_game'
    GS_MainMenu = GS_MainMenu or require 'gs_menu'
    self.x = 0
    self.y = 0
    self.w = 50
    self.h = 30
    self.text = text
    self.callback = callback
    self.hover = false
    self.font = font
    self.color = {}
    self.color.text = {1, 0.8, 0, 1}
    self.is_down = false
    self.was_down = false
    self.timer = Timer.new()
end

function UI_Button:draw()
    local font = self.font or love.graphics.getFont()
    local text_y = self.y + self.h*0.5 - font:getHeight()*0.5

    if self.hover then
        love.graphics.setColor(0.95, 0, 0, 1)
    else
        love.graphics.setColor(1, 0, 0, 0.75)
        -- love.graphics.setColor(1, 0.6, 0, 0.9)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 5, 5)
    love.graphics.setFont(font)
    love.graphics.setColor(self.color.text)
    love.graphics.printf(self.text, self.x, text_y, self.w, "center")
    love.graphics.setColor(1, 1, 1, 1)
    
end

function UI_Button:isHoverAt(x, y)
    return x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h
end

function UI_Button:updateMobile(dt)
    local touches = love.touch.getTouches()

    if not IS_MOBILE and DEBUG.MOUSE_IS_FINGER then -- mouse acts like a finger
        local mx, my = love.mouse.getPosition()
        if love.mouse.isDown(1) and self:isHoverAt(mx, my) then
            self.is_down = true

            if not self.was_down then
                self.hover = true
                Timer.after(0.1, function() 
                    self.hover=false;
                end)
                Timer.after(0.15, function() 
                    self.callback(self)
                end)
            end
        end
    else
        for _, touch in ipairs(touches) do
            local xt, yt = love.touch.getPosition(touch)
            if self:isHoverAt(xt, yt) then
                self.is_down = true
                if not self.was_down then
                    self.hover = true
                    Timer.after(0.1, function() 
                        self.hover=false;
                    end)
                    Timer.after(0.15, function() 
                        self.callback(self)
                    end)
                end
            end
        end
    end
end

function UI_Button:updateDesktop(dt)
    self.hover = self:isHoverAt(love.mouse.getPosition())
end


function UI_Button:update(dt)
    self.was_down = self.is_down
    self.is_down = false

    if IS_MOBILE or DEBUG.MOUSE_IS_FINGER then
        self:updateMobile()
    else
        self:updateDesktop()
    end
    -- self.timer:update(love.timer.getDelta())
end

function UI_Button:mousepressed(x, y)
    if self.hover and not DEBUG.MOUSE_IS_FINGER then
        self.is_down = true
        self.callback(self)
    end
end

function UI_Button:isDown(id)
    return self.is_down
end

function UI_Button:isPressed(id)
    return self.is_down and not self.was_down
end

function UI_Button:isReleased(id)
    return not self.is_down and self.was_down
end

--################################
--=         FACTORIES         =--

function UI_Button.mainMenuBtn()
    return UI_Button('menu', function()
        GAME_STATE_MACHINE:empty()
        GAME_STATE_MACHINE:push(GS_MainMenu():load())
    end, FONT.MAIN_MENU)
end

function UI_Button.newGameBtn()
    return UI_Button('new game', function()
        GAME_STATE_MACHINE:empty()
        GAME_STATE_MACHINE:push(GS_Game():load())
    end, FONT.MAIN_MENU)
end

function UI_Button.exitBtn()
    return UI_Button('exit', function(ui_btn)
        -- print('exit pressed ?', ui_btn, ui_btn.is_down, ui_btn.was_down)
        -- if ui_btn:isPressed() then
            love.event.quit()
        -- end
    end, FONT.MAIN_MENU)
end

function UI_Button.scoreboardBtn()
    return UI_Button('scoreboard', function()
        local gs_scoreboard = GAME_STATE_MACHINE:push(GS_Scoreboard())
        gs_scoreboard:load()
    end, FONT.MAIN_MENU)
end

function UI_Button.settingsBtn()
    return UI_Button('settings', function()
        -- GAME_STATE_MACHINE:push(GS_Training():load())
    end, FONT.MAIN_MENU)
end

return UI_Button






