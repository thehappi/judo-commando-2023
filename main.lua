-- NAMING CONVENTION

-- variables/functions: snake_case.
-- constants: UPPER_CASE.
-- classes: PascalCase.
-- private: __snake_case.

--===========================#
-- config
IS_MOBILE = love.system.getOS() == 'iOS' or love.system.getOS() == 'Android'

if IS_MOBILE then
    love.window.setVSync(0)
else
    love.window.setVSync(1)
end

love.filesystem.setRequirePath('/?.lua;'
    .. 'lib/?.lua;'
    .. 'lib/hump/?.lua;'
    .. 'src/?.lua;'
    .. 'src/game_state/?.lua;'
    .. 'src/ui/?.lua;'
    .. 'src/anim/?.lua;'
)

if arg[#arg] == "vsc_debug" then 
    require("lldebugger").start() 
end

io.stdout:setvbuf("no")
love.graphics.setDefaultFilter("nearest", "nearest");

--===========================#
Timer           =require 'hump.timer'
V2              =require 'hump.vector'
Signal          =require 'hump.signal'
Tiny            =require 'tiny'
Xtype           =require "xtype"
Luaoop          =require 'lib.luaoop'
Class           =Luaoop.class
--===========================#
-- GAME
lovepad         =require "lovepad"

require 'utils'
require 'constants'
require 'game_config'

GameStateMachine = require 'game_state_machine'
GameStateInterface = require 'game_state_interface'

GS_SplashScreen = require 'gs_splash_screen'
GS_MainMenu = require 'gs_menu'
GS_Game = require 'gs_game'

require 'anim_atlas'
require 'component'
require 'st_hero'
require 'st_enemy'
require 'st_monkey'
require 'entity'
require 'system'
require 'system_collision'
require 'system_physic'
require 'system_animate'
require 'system_ai'

local Game = require 'game'
local SoundManager = require 'sound_manager'

GAME_STATE_MACHINE = nil
GAME=nil

SHADER_IS_HIT = love.graphics.newShader[[
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
        vec4 pixel = Texel(texture, texture_coords ); //This is the current pixel color
        if (pixel.a > 0.0) {
            pixel.rgb = vec3(1, 0, 0);
        }
        return pixel * color;
    }  
]]

function love.load()
    GAME_STATE_MACHINE = GameStateMachine()
    -- GAME_STATE_MACHINE:push(GS_SplashScreen():load())
    GAME_STATE_MACHINE:push(GS_Game():load())
    -- GAME_STATE_MACHINE:push(GS_MainMenu():load())
end

function love.update(dt)
--     SoundManager:update()
    GAME_STATE_MACHINE:first():update(dt)
    Timer.update(dt)
end

function love.draw()
    GAME_STATE_MACHINE:first():draw()
end

function love.keypressed(k)
    local gs = GAME_STATE_MACHINE:first()
    if gs.keypressed then
        gs:keypressed(k)
    end
end

function love.mousepressed(x, y, button)
    local gs = GAME_STATE_MACHINE:first()
    if gs.mousepressed then
        gs:mousepressed(x, y, button)
    end
end