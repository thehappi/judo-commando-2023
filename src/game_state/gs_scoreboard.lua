local UI_Button = UI_Button or require 'ui_button'
local UI_Scoreboard = UI_Scoreboard or require 'ui_scoreboard'
local Scoreboard = Scoreboard or require 'scoreboard'
local GS_MainMenu = GS_MainMenu or require 'gs_menu'

local GS_Scoreboard = Class('GS_Scoreboard')

function GS_Scoreboard:__construct()
    self.show_nth_first = 7
    self.scoreboard = Scoreboard

    self.y = 100
    -- = BACK BUTTON
    self.back_button = UI_Button('back', function()
        GAME_STATE_MACHINE:pop()
        self.st_parent.buttons_enabled = true
    end, FONT.MAIN_MENU)
    self.back_button.w = 75
    self.back_button.h = 30
    self.back_button.x = love.graphics.getWidth() - self.back_button.w - 10
    self.back_button.y = 10

    -- = SCOREBOARD LAYOUTS
    self.ui_personal = UI_Scoreboard('PERSONAL BEST', SCREEN_W * 0.1, self.y)
    self.ui_online = UI_Scoreboard('ONLINE BEST', SCREEN_W * 0.65, self.y)
    return self
end

function GS_Scoreboard:load()
    self.scoreboard:connect()
    self.scoreboard:fetchOnline()
    self.ui_online:setEntries(self.scoreboard.online)

    self.scoreboard:fetchLocal()
    self.ui_personal:setEntries(self.scoreboard.personal)

    self.st_parent = GAME_STATE_MACHINE:below()
    self.st_parent.buttons_enabled = false
    return self
end

function GS_Scoreboard:update(dt)
    if Xtype.is(self.st_parent, GS_MainMenu) then
        self.st_parent:update(dt)
    end
    self.back_button:update()
end

function GS_Scoreboard:draw()
    love.graphics.clear()
    --= draw parent state as background
    if self.st_parent then 
        self.st_parent:draw()
    end
    --=
    self.back_button:draw()
    --= scoreboards
    self.ui_personal:draw()
    self.ui_online:draw()
end

function GS_Scoreboard:keypressed(k)
    if k == 'p' then
        GAME_STATE_MACHINE:pop()
    end
    if k == 'escape' then
        love.event.quit()
    end
end

function GS_Scoreboard:mousepressed(x, y, button)
    self.back_button:mousepressed(x, y)
end

function GS_Scoreboard:exit()
    --= prevents the exit button from being pressed instantly
    if Xtype.is(self.st_parent, GS_MainMenu) then
        self.st_parent.exit_button.was_down = true
        self.st_parent.exit_button.is_down = true
    end
end

return GS_Scoreboard

