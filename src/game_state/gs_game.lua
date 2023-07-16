local Tiny = Tiny or require 'lib.tiny'
local Game = Game or require 'game'
local UI_Button = UI_Button or require 'ui_button'
local GS_Pause = GS_Pause or require 'gs_pause'
local GS_GameOver = GS_GameOver or require 'gs_gameover'

--============= GAME RUNNING ==============#

local GS_Game = Class('GS_Game', GameStateInterface)

function GS_Game:__construct()
    GAME=Game()
    self.button_pause = UI_Button('pause', function()
        self:pause()
    end, FONT.MAIN_MENU)
    self.button_pause.y = 5
    self.button_pause.w = 100
    self.button_pause.h = 24
    self.button_pause.x = love.graphics.getWidth() * 0.5 - self.button_pause.w * 0.5
    self.button_pause.color.text = {1, 0.8, 0, 1}
    return self
end

function GS_Game:load()
    lovepad:enable()
    GAME:load()
    if IS_MOBILE or DEBUG.MOUSE_IS_FINGER then
        lovepad:setGamePad()
    end
    return self
end

function GS_Game:update(dt)
    GAME:update(dt)
    if GAME.e_hero.c_health.hp == 0 and GAME.is_game_over then
        GAME:freeze_enemies()
    end
    if GAME.is_game_over then
        GAME_STATE_MACHINE:push(GS_GameOver():load())
    end
    self.button_pause:update(dt)
end

function GS_Game:draw()
    -- self.effect(function()
    GAME:draw()
    -- end)
    self.button_pause:draw()
end

function GS_Game:keypressed(k)
    if k == 'b' then
        GAME_STATE_MACHINE:empty()
        GAME_STATE_MACHINE:push(GS_Game():load())
    end
    if k == 'd' then
        GAME:freeze_enemies()
        GAME_STATE_MACHINE:push(GS_DebugMenu():load())
    end
    if k == 'escape' then
        love.event.quit()
    end
    if k == 'p' then
        self:pause()
    end
end

function GS_Game:exit()
    if GAME then
        GAME:destructor()
        GAME = nil
    end
end

function GS_Game:pause()
    GAME:freeze()
    GAME_STATE_MACHINE:push(GS_Pause():load())
end

function GS_Game:resume()
    GAME:unfreeze()
end

function GS_Game:mousepressed(x, y)
    self.button_pause:mousepressed(x, y)
end

function GS_Game:backgrounded()
    lovepad:disable()
end

function GS_Game:foreground()
    lovepad:enable()
end

return GS_Game
