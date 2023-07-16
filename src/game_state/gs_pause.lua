local UI_Button = UI_Button or require 'ui_button'

local GS_Pause = Class('GS_Pause', GameStateInterface)

function GS_Pause:__construct()
    local screen_h = love.graphics.getHeight()
    local screen_w = love.graphics.getWidth()
    local button_layout_h = screen_h * 0.7
    self.buttons_enabled = true

    local button_margin_bot = 16

    self.font = FONT.MAIN_MENU

    self.buttons = {}
    self.buttons[1] = UI_Button('resume', function() self:resume() end, self.font)
    self.buttons[2] = UI_Button.newGameBtn()
    self.buttons[3] = UI_Button.scoreboardBtn()
    self.buttons[4] = UI_Button.settingsBtn()
    self.buttons[5] = UI_Button.exitBtn()

    --= button layout vertical centering
    local button_h = 30
    local button_layout_y = (screen_h * 0.5) - ((#self.buttons-1) * (button_h + button_margin_bot)) * 0.5


    for i, button in ipairs(self.buttons) do
        button.h = button_h
        button.w = 200
        button.x = screen_w * 0.5 - button.w * 0.5
        button.y = button_layout_y + (i - 1) * (button_h + button_margin_bot)
    end
    return self
end

function GS_Pause:load()
    local c = 0.4
    local game_shade = {c, c, c, 1}

    GAME.draw_color.map = game_shade
    GAME.draw_color.ui = game_shade
    GAME.draw_color.anims = game_shade
    GAME.draw_color.bg = game_shade
    return self
end

function GS_Pause:update()
    for _, button in pairs(self.buttons) do
        button:update()
    end
end

function GS_Pause:draw()
    -- self.effect(function()
    GAME:draw()
    -- end)
    --= buttons
    if self.buttons_enabled then
        for _, button in pairs(self.buttons) do
            button:draw()
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function GS_Pause:keypressed(k)
    if k == 'escape' then
        love.event.quit()
    elseif k == 'p' then
        self:resume()
    end
end

function GS_Pause:mousepressed(x, y, button)
    for _, button in pairs(self.buttons) do
        button:mousepressed(x, y)
    end
end

function GS_Pause:exit()
    local game_shade = {1, 1, 1, 1}

    GAME.draw_color.map = game_shade
    GAME.draw_color.ui = game_shade
    GAME.draw_color.anims = game_shade
    GAME.draw_color.bg = game_shade
end

function GS_Pause:resume()
    GAME:unfreeze()
    GAME_STATE_MACHINE:pop()
end

return GS_Pause