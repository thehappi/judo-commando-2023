local Scoreboard = Scoreboard or require 'scoreboard'
local UI_Button = UI_Button or require 'ui_button'
local UI_Scoreboard = UI_Scoreboard or require 'ui_scoreboard'

local GS_GameOver = Class('GS_GameOver', GameStateInterface)

function GS_GameOver:__construct()
    self.show_nth_first = 7
    self.scoreboard = Scoreboard

    self.text_title = 'GAME OVER'
    self.text_int = '[SPACE] : new game'
    self.text_int2 = '[ESC] : exit'

    self.win_w = love.graphics.getWidth()
    self.win_h = love.graphics.getHeight()
    self.y = 15

    self.t = 0
    self.interval = 0.2

    -- = SCOREBOARD LAYOUTS
    local laouts_y = self.y + 60
    self.ui_personal = UI_Scoreboard('PERSONAL BEST', SCREEN_W * 0.1, laouts_y)
    self.ui_online = UI_Scoreboard('ONLINE BEST', SCREEN_W * 0.65, laouts_y)

    -- = BUTTONS
    self.font = FONT.MAIN_MENU
    self.button = {}
    self.button.new_game = UI_Button.newGameBtn()
    self.button.new_game.w = 200
    self.button.new_game.h = 30
    self.button.new_game.x = SCREEN_W * 0.5 - self.button.new_game.w - 10
    self.button.new_game.y = SCREEN_H - self.button.new_game.h - 10 

    self.button.main_menu = UI_Button.mainMenuBtn()

    self.button.main_menu.w = 200
    self.button.main_menu.h = 30
    self.button.main_menu.x = SCREEN_W * 0.5 + 10
    self.button.main_menu.y = SCREEN_H - self.button.main_menu.h - 10 
    
    return self
end

function GS_GameOver:load()
    local c = 0.4
    local game_shade = {c, c, c, 1}
    
    GAME.draw_color.map = game_shade
    GAME.draw_color.ui = {c, c, c, 0}
    GAME.draw_color.anims = game_shade
    GAME.draw_color.bg = game_shade

    --= ONLINE
    local new_online_best = Scoreboard:saveOnline(GAME.score, 'ABC')
    if new_online_best then
        self.ui_online:setTitle('NEW ONLINE BEST')
    end
    self.ui_online:setEntries(self.scoreboard.online)

    --= PERSONAL
    local new_personal_best = Scoreboard:savePersonal(GAME.score, 'ABC')
    if new_personal_best then
        self.ui_personal:setTitle('NEW PERSONAL BEST')
    end
    self.ui_personal:setEntries(self.scoreboard.personal)
    return self
end

function GS_GameOver:update(dt)
    self.t = self.t + dt

    if self.t >= (self.interval * 2) then
        self.t = (self.interval * 2) - self.t
    end

    if IS_MOBILE then
        GS_GameOver:keypressed(nil)
    end

    self.button.new_game:update(dt)
    self.button.main_menu:update(dt)
end

function GS_GameOver:draw()
    love.graphics.clear()
    GAME:draw()

    local new_score = neatnumber(GAME.score)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(GAME.font_game_over)
    love.graphics.printf(self.text_title, 0,  self.y, self.win_w, 'center')
    love.graphics.printf('' .. new_score, 0,  self.y+50, self.win_w, 'center')

    --= scoreboards
    self.ui_personal:draw()
    self.ui_online:draw()

    self.button.new_game:draw()
    self.button.main_menu:draw()
end

function GS_GameOver:keypressed(k)
    if k == 'space' or (IS_MOBILE and lovepad:isDown('space')) then
        GAME:destructor()
        GAME_STATE_MACHINE:set(GS_Game():load())
    end
    if k == 'escape' then
        love.event.quit()
    end
end

function GS_GameOver:mousepressed(x, y)
    self.button.new_game:mousepressed(x, y)
    self.button.main_menu:mousepressed(x, y)
end

return GS_GameOver