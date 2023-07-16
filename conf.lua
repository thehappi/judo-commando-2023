--========================
--=> GIT

-- henryTeteDeBois
-- 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 

--========================
--=> NAMING CONVENTION

-- variables/functions: snake_case.
-- constants: UPPER_CASE.
-- classes: PascalCase.
-- private: __snake_case.

-- @param type optional string.
-- @return type optional string.

function love.conf(t)
    local window_ratio = 9/16
    t.console = false
    t.window.width = 1800
    t.window.height = 700
    -- t.window.height = math.floor(t.window.width * window_ratio)
    t.modules.audio = true              -- Enable the audio module (boolean)
    t.modules.font = true               -- Enable the font module (boolean)
    t.modules.graphics = true           -- Enable the graphics module (boolean)
    t.modules.image = true              -- Enable the image module (boolean)
    t.modules.math = true               -- Enable the math module (boolean)
    t.modules.sound = true              -- Enable the sound module (boolean)
    t.modules.window = true             -- Enable the window module (boolean)
    t.modules.system = true             -- Enable the system module (boolean)
    t.modules.timer = true              -- Enable the timer module (boolean), Disabling it will result 0 delta time in love.update
    t.modules.touch = true              -- Enable the touch module (boolean)
    t.modules.event = true              -- Enable the event module (boolean)

    t.modules.thread = false             -- Enable the thread module (boolean)
    t.modules.data = false               -- Enable the data module (boolean)
    t.modules.joystick = false           -- Enable the joystick module (boolean)
    t.modules.physics = false            -- Enable the physics module (boolean)  
    t.modules.video = false              -- Enable the video module (boolean)

    -- if is_mobile then
    t.modules.keyboard = true       -- Enable the keyboard module (boolean)
    t.modules.mouse = true          -- Enable the mouse module (boolean)
    t.externalstorage = true
    t.audio.mic = false              -- Enable the microphone module (boolean)
    -- end
end