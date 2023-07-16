local TL = 32
local IS_MOBILE = true

Preset = {
    C_Move_Hrz = {
        St_Ground={acc=TL*200,dec=TL*70,max=TL*8,min=TL*1},
        St_MkGround={acc=TL*200,dec=TL*70,max=TL*5.5,min=TL*1},
        St_Jump={acc=TL*80,dec=TL*80,max=TL*7,min=TL*1},
        St_Platf={acc=TL*200,dec=TL*40,max=TL,min=TL*1},
        St_EnGround={
            acc=TL*200,dec=TL*40,max=TL*.8,min=TL*.8
        },
        St_NinjaDash={acc=TL*800,dec=TL*40,max=TL*5.5,min=TL*1},
    },
}

Combo ={
    St_Guard1Front = {
        damage=6, pow_vy=-160
    }
}

DEBUG = {
    MOUSE_IS_FINGER = true
}


SCREEN_W = love.graphics.getWidth()
SCREEN_H = love.graphics.getHeight()

DEBUG_HITBOX = false
DEBUG_RECT = false
DEBUG_NAVMAP = false

FONT = {}
FONT.MAIN_MENU = love.graphics.newFont('asset/font/8_BIT_WONDER.ttf', 12)
FONT.SCORE = love.graphics.newFont('asset/font/Pixelation.ttf', 16)
FONT.JAP = love.graphics.newFont('asset/font/OtomanopeeOne-Regular.ttf', 14)

SCOREBOARD = {}
SCOREBOARD.DEFAULT_ENTRIES = {
    {name='ABCDEF', score=100000},
    {name='GHIJKL', score=50000},
    {name='MNOPQR', score=10000},
    {name='MNOPQR', score=8000},
    {name='MNOPQR', score=2000},
    {name='MNOPQR', score=2000},
    {name='MNOPQR', score=2000},
}

GRADIENT = {}
GRADIENT.MAIN_MENU = love.graphics.newGradientMesh('vertical',
    rgb_to_factor({0, 0, 0}),
    rgb_to_factor({5, 0, 10}),
    rgb_to_factor({10, 0, 10}),
    rgb_to_factor({10, 0, 20}),
    rgb_to_factor({10, 0, 25}),
    rgb_to_factor({20, 0, 50}),
    rgb_to_factor({30, 0, 74}),
    rgb_to_factor({30, 0, 74}),
    rgb_to_factor({20, 0, 80}),
    rgb_to_factor({20, 0, 90}),
    rgb_to_factor({10, 0, 100}),
    rgb_to_factor({0, 0, 115}),
    rgb_to_factor({0, 0, 135}),
    rgb_to_factor({0, 0, 150}),
    rgb_to_factor({0, 0, 165}),
    rgb_to_factor({0, 0, 192}),
    rgb_to_factor({0, 0, 208}),
    rgb_to_factor({24, 0, 208}),
    rgb_to_factor({130, 14, 130}),
    rgb_to_factor({250, 50, 70}),
    rgb_to_factor({250, 160, 35}),
    {1, 0.6, 0},
    rgb_to_factor({75, 70, 206})
)

GRADIENT.IN_GAME = love.graphics.newGradientMesh('vertical',
    rgb_to_factor({0, 0, 56}),
    -- self:rgb_to_factor({0, 0, 64}),
    -- self:rgb_to_factor({0, 0, 80}),
    -- self:rgb_to_factor({0, 0, 96}),
    -- self:rgb_to_factor({0, 0, 112}),
    -- self:rgb_to_factor({0, 0, 120}),
    -- self:rgb_to_factor({0, 0, 136}),
    -- self:rgb_to_factor({0, 0, 152}),
    rgb_to_factor({0, 0, 168}),
    -- self:rgb_to_factor({0, 0, 176}),
    -- self:rgb_to_factor({0, 0, 192}),
    -- self:rgb_to_factor({0, 0, 208}),
    -- self:rgb_to_factor({24, 0, 208}),
    -- self:rgb_to_factor({48, 0, 208}),
    -- self:rgb_to_factor({56, 14, 208}),
    -- self:rgb_to_factor({65, 26, 208}),
    rgb_to_factor({77, 41, 206})
    -- self:rgb_to_factor({88, 55, 206}),
    -- self:rgb_to_factor({95, 70, 206})
)

-- vitesse: pixel par seconde
ENEMY_WALK_SPEED = TL * 0.7 
ENEMY_LADDER_SPEED = TL * (IS_MOBILE and 2 or 3)



HERO_RUN_SPEED = TL * (IS_MOBILE and 7 or 8)
-- HERO_FALL_SPEED = TL * (IS_MOBILE and 8 or 12)

BULLET_SPEED = HERO_RUN_SPEED * 0.9
ROCKET_SPEED = HERO_RUN_SPEED * 1.2

--=
ROCKET_RANGE_MIN = TL * 3
ROCKET_RANGE_MAX = (SCREEN_W * 0.5) + (TL * 2)
ROCKET_AIMING_AT = 0.15
ROCKET_AIMING_ANIM_TIME = 0.5
ROCKET_IDLE_TIME = 0.35
ROCKET_TOTAL_TIME = ROCKET_AIMING_AT + ROCKET_AIMING_ANIM_TIME + ROCKET_IDLE_TIME
--
GUN_RANGE_MIN = TL * 2
GUN_RANGE_MAX = TL * 12
GUN_IDLE_TIME = 0.5





