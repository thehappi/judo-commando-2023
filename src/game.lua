local Bump = Bump or require 'lib.bump'
local Tiny = Tiny or require 'lib.tiny'
local Gamera = Gamera or require 'lib.gamera'
local Parallax = Parallax or require 'lib.parallax'
local moonshine = moonshine or require 'lib.moonshine.init'
local profile = require("profiler")

local GameSignal = GameSignal or require 'gamesignal'
local Map = Map or require 'map'
local NavMap, _, _ = NavMap or require 'navmap'
local GameUi = GameUi or require 'game_ui'

local Game=Class('Game')

function Game:__construct()

    self.score=0
    self.level=1
    self.ai_enabled = false

    self.evt = {
        on_game_over=false,
        on_game_over_trg=false,
        on_level_clear=false,
        on_level_clear_trg=false,
    }

    self.game_ui = GameUi.new()
    self.font = love.graphics.newFont('asset/font/Pixelation.ttf')
    self.font_score = love.graphics.newFont('asset/font/Pixelation.ttf', 24)
    self.font_game_over = love.graphics.newFont('asset/font/Pixelation.ttf', 36)
    -- = init ECS engine & systems
    self.tiny_world = Tiny.world( 
        S_DrawBodyOutline,
        S_Collision,
        S_Physic,
        S_MapInterractions,
        S_StateMachineUpdate,
        S_StateMachineSetNewState,
        S_HeroWanderSt,
        S_UpdateBumpPosition,
        S_PlatformState,
        S_Animate,
        S_Animate_Hero_Atlas,
        S_Animate_Enemy_Atlas,
        S_Animate_Fx,
        S_PadListener,
        S_OldPadUpdater,
        S_ResolveEvents,
        S_ProjectileSolver,
        S_DelOnAnimOver,
        S_FxTrailGenerator,
        S_Ai,
        -- S_Ai2,
        S_DrawScoreText,
        S_UpdateScoreText,
        S_BlinkUpdate,
        S_UpdateJewel,
        S_UpdateLifeUp,
        S_Pickable,
        S_HandleDeadEnemies,
        S_ClearOutbound,
        S_DebrisColl,
        S_EnemyCollision,
        S_Melee_Range,
        S_BombSolver,
        S_IsGuarding
    )
    -- = init collision engine
    self.bump_world=Bump.newWorld(32)
    --=
    self.cam=nil
    self.map=Map()
    self.navmap=NavMap()
    -- = entities
    self.entites = {}
    self.e_enemies = {}
    self.e_hero=nil

    -- = __private
    self.__toadd = {}
    self.__todel = {}
    self.__dbg_segments = {} -- x1, y1, x2, y2, color
    self.__dbg_rects = {} -- x1, y1, w, h, color
    self.__debug_bz_curves = {}

    self.Score_Table = {
        Base=400,
        Gun=600,
        Bomb=800,
        Rocket=800,
        Ninja=1000,
        Jewel=200,
        Jewel_Set=6000,
        Level_Clear=1500
    }
    self.enemy_pool = {
        {Base=0,   Gun=0,  Bomb=0,  Rocket=0,  Ninja=1},
        {Base=5,   Gun=1,  Bomb=0,  Rocket=0,  Ninja=0},
        {Base=5,   Gun=1,  Bomb=2,  Rocket=2,  Ninja=0},
        {Base=6,   Gun=1,  Bomb=2,  Rocket=2,  Ninja=3},
        {Base=7,   Gun=2,  Bomb=3,  Rocket=3,  Ninja=3},
        {Base=8,   Gun=3,  Bomb=4,  Rocket=3,  Ninja=4},
        {Base=9,   Gun=4,  Bomb=4,  Rocket=4,  Ninja=5}, -- 26
        {Base=13,  Gun=4,  Bomb=4,  Rocket=4,  Ninja=0},
        -- {Base=13,  Gun=4,  Bomb=4,  Rocket=4,  Ninja=5},
        {Base=13,  Gun=6,  Bomb=5,  Rocket=5,  Ninja=5},
        {Base=14,  Gun=6,  Bomb=6,  Rocket=6,  Ninja=6},
        {Base=14,  Gun=7,  Bomb=6,  Rocket=8,  Ninja=7}, -- 42
        {Base=18,  Gun=7,  Bomb=6,  Rocket=8,  Ninja=7},
        {Base=22,  Gun=7,  Bomb=6,  Rocket=8,  Ninja=7}, -- 50
    }

    self.map_pool = {
        -- lvl1 = {8}, -- level 1
        lvl1 = {1}, -- level 1e
        lvl2 = {1}, -- level 1e
        -- lvl1 = {1, 2, 3}, -- level 1
        -- lvl2 = {4, 5, 6, 7, 8, 9, 10, 11, 12, 13} -- level 2+
        -- {4, 6,  9},
        -- {4, 7, 10},
        -- {4},
    }
    self.map_available = table.clone(self.map_pool.lvl2)

    --= BACKGROUND
    self.background_gradient = GRADIENT.IN_GAME
    self.background_parallaxes = {}
    self.parallax = nil
    self.parallax_z1_img = love.graphics.newImage('asset/parallax-1.png')
    self.parallax_z2_img = love.graphics.newImage('asset/parallax-2.png')
    self.parallax_z0_img = love.graphics.newImage('asset/ground.png')

    self.world = {l = -2500, t = -1000, w = 100000, h = 1000 + Tl.Dim * 25, sc=2}
    if IS_MOBILE then
        self.world.sc = 1.4
    else
        self.world.sc = 1.6
    end
    self.ui_scale = 2
    self.world.bottom = self.world.t + self.world.h

    self.is_lvl_clear = false
    self.is_game_over = false

    love.graphics.setFont(self.font, 12)

    self.psystem_level_clear = love.graphics.newParticleSystem( Spritesheet.Item_And_Fx, 40 )
    self.psystem_level_clear:setParticleLifetime(0.2, 1) -- Particles live at least 2s and at most 5s.
    self.psystem_level_clear:setOffset(0, 0)
	self.psystem_level_clear:setEmissionRate(40)
	self.psystem_level_clear:setEmissionArea('ellipse', 8, 4)
	self.psystem_level_clear:setSpread(math.pi)
	self.psystem_level_clear:setSizeVariation(0.5)
	self.psystem_level_clear:setSpeed(48, 64)
	self.psystem_level_clear:setDirection(-math.pi * 0.5)
	self.psystem_level_clear:setLinearAcceleration(-10, -20, 10, -256) -- Random movement in all directions.
    self.psystem_level_clear:setQuads(Atlas.Particle['level_clear'].quads)

    self.psystem_blood = love.graphics.newParticleSystem( Spritesheet.Item_And_Fx, 30 )
    self.psystem_blood:setParticleLifetime(0.5, 0.6) -- Particles live at least 2s and at most 5s.
	self.psystem_blood:setEmissionArea('ellipse', 2, 2)
    self.psystem_blood:setSpeed( 90, 120 )
    self.psystem_blood:setLinearAcceleration(0, 400, -64, 500 )
    self.psystem_blood:setQuads(Atlas.Particle['blood'].quads)

    self.psystems = {
        pickable = {},
        blood = {},
        smoke = {},
        flare = {}
    }
    self.e_debris = {}

    self.monkey_timeout = nil
    self.monkey_timer = 0
    self.e_monkeys = {}

    self.dbg_alpha = 1

    self.draw_color = {
        map =   {1, 1, 1, 1},
        ui =    {1, 1, 1, 1},
        anims = {1, 1, 1, 1},
        debug = {0, 0, 1, 0.4},
        bg =    {1, 1, 1, 1}, -- background
    }

    self.effect = moonshine(moonshine.effects.scanlines)
    self.effect.scanlines.width = IS_MOBILE and 3 or 1
    self.effect.scanlines.opacity = IS_MOBILE and 1 or 0.7
end

--==========================#
-- = 

function Game:destructor()
    Tiny.clearSystems(self.tiny_world)
    Tiny.clearEntities(self.tiny_world)
    Tiny.refresh(self.tiny_world)
    self.bump_world=nil
    self.tiny_world=nil
    self.e_enemies=nil
    self.e_player=nil
    collectgarbage("collect")
    GameSignal:clear()
end

--==========================#
-- = 

function Game:load()

    self:initScoreObserver()

    self.level = 1
    -- self:unfreeze_enemies()
    self:freeze_enemies()

    self.building =  {name = 'building'}
    self.bump_world:add(self.building, 0, 0, 10, self.world.bottom)

    self.score=0
    self:load_level(self.level)
    self.ai_enabled = true

    --=
    local spawn_hero_x = Tl.Dim * 4.5
    local spawn_hero_y = self.map.y + self.map.h - Tl.Dim * 3
    self.e_hero=E_Hero(spawn_hero_x, spawn_hero_y)
    self.e_hero.c_anim.dir = 1
    --=
    self.cam = Gamera.new(self.world.l, self.world.t, self.world.w, self.world.h)
    self.cam:lock_on(self.e_hero.c_b)
    self.cam:setScale(self.world.sc)

    self.ground_y = self.cam

    self.parallax_z0 = Parallax.new(self.cam, 1)
    self.parallax_z1 = Parallax.new(self.cam, 1, 1)
    self.parallax_z2 = Parallax.new(self.cam, 1, 1)

    self.ground = {
        tileset=love.graphics.newImage('asset/ground-tileset.png'),
        road= love.graphics.newImage('asset/ground-road.png'),
        parallaxs={},
        quads= {},
        y=0,
        h=0
    }

    self.ground.h = self.ground.tileset:getHeight()
    self.ground.y = self.world.bottom - self.ground.h

    self.ground.parallaxs = {
        middle = Parallax.new(self.cam, 1),
        road = Parallax.new(self.cam, 1)
    }

    self.ground.quads = {
        step_l = love.graphics.newQuad(33, 0, 32, 40, self.ground.tileset:getDimensions()),
        middle = love.graphics.newQuad(66, 0, 32, 40, self.ground.tileset:getDimensions()),
        step_r = love.graphics.newQuad(99, 0, 32, 40, self.ground.tileset:getDimensions()),
    }

    self.is_lvl_clear = false

    -- = JEWEL COLLECTION
    self.game_ui:init()

    -- self.tiny_world:refresh()
    
end

function Game:drawProfilerReport()
    -- local report = profile.query(10)
    -- local y = 100
    -- love.graphics.setColor(1, 1,0, 1)
    -- love.graphics.setFont(love.graphics.newFont(10))
    -- for i, v in ipairs(report) do
    -- love.graphics.print(profile.report(10), 0, y)
        -- y = y + 20
    -- end
end

--==========================#
-- = FREE MEMORY

function Game:free_level()

    self.map:unload()

    for i=#self.e_enemies, 1, -1 do
        self:del_e(self.e_enemies[i])
    end

    self.e_enemies={}
    self.e_monkeys={}

    self.is_lvl_clear = false
    self.is_lvl_loaded = true
    self.on_lvl_clear_trg = false

    collectgarbage("collect")
end

--==========================#
-- = SPAWN ENEMIES
--=

-- function Game:

function Game:spawn_enemy(type)
    local spawners = self.navmap.spawners
    local spawner_i = math.noise1d(love.math.random(1, #spawners))
    spawner_i = math.ceil(spawner_i * #spawners)

    local spawn_tl = spawners[spawner_i]
    local spawn_x = spawn_tl.c_b:mid_x()
    local spawn_y = spawn_tl.c_b:bot() - 32
    -- spawn_x = Tl.Dim * 0.5
    -- spawn_y = -Tl.Dim * 10
    local e_enemy = nil

    if type == E_Enemy.Type.Base then
        e_enemy = E_BaseSoldier(nil, spawn_x, spawn_y)

    elseif type == E_Enemy.Type.Gun then
        e_enemy = E_GunSoldier(spawn_x, spawn_y)

    elseif type == E_Enemy.Type.Rocket then
        e_enemy = E_RocketSoldier(spawn_x, spawn_y)

    elseif type == E_Enemy.Type.Bomb then
        e_enemy = E_BombSoldier(spawn_x, spawn_y)

    elseif type == E_Enemy.Type.Ninja then
        e_enemy = E_Ninja(spawn_x, spawn_y)

    elseif type == E_Enemy.Type.Monkey then
        e_enemy = E_Monkey()
        table.insert(self.e_monkeys, e_enemy)
    end

    if e_enemy then
        table.insert(self.e_enemies, e_enemy)
    end
    return e_enemy
end

--==========================#
-- = PICK A RANDOM MAP FROM POOL
--=

function Game:pickRandomMap(level)

    if level == 1 then
        local map_pool = self.map_pool.lvl1
        return map_pool[math.random( 1, #map_pool )]
    end

    if #self.map_available == 0 then
        self.map_available = table.clone(self.map_pool.lvl2)
    end

    local map_cnt = #self.map_available
    local map_idx = love.math.random(1, map_cnt)
    local map = self.map_available[map_idx]

    table.remove(self.map_available, map_idx)
    return map
end

--==========================#
-- = LOAD LEVEL
--=

function Game:load_level(level, bz_goal_x)
    -- profile.start()

    if level > 1 then
        self:free_level()
    end

    self.level = level

    if self.map.is_loaded then
        self.map.x = bz_goal_x
        self.bump_world:update(self.building, self.map.x, 0, self.map.w, self.world.bottom)
        return
    end

    -- = MAP =--
    bz_goal_x = bz_goal_x or 0
    self.navmap.spawners = {}

    self.map:load(self:pickRandomMap(level), bz_goal_x)
    self.navmap:load(self.map)
    self.bump_world:update(self.building, self.map.x, 0, self.map.w, self.world.bottom)
    -- = ENEMIES =--
    local enemy_pool = nil
    if level > #self.enemy_pool then
        enemy_pool = self.enemy_pool[#self.enemy_pool]
    else
        enemy_pool = self.enemy_pool[level]
    end 
    -- = count enemies in pool
    local level_enemy_cnt = 0
    for _, enemy_cnt in pairs(enemy_pool) do
        level_enemy_cnt = level_enemy_cnt + enemy_cnt
    end
    self.level_enemy_cnt = level_enemy_cnt
    -- = spawn enemies
    for enemy_type, enemy_cnt in pairs(enemy_pool) do
        for i=1, enemy_cnt do
            self:spawn_enemy(enemy_type)
        end
    end
    -- = AI disabled if level > 1
    -- = Enable AI on hero landing new level
    if level == 1 then
        self.ai_enabled = true
    else
        self.ai_enabled = false
    end
    -- = monkey
    self.monkey_timer = 0
    if level < 3 then
        self.monkey_timeout = 1000--80 -- seconds
    else
        self.monkey_timeout = 1000 -- seconds
    end

    -- profile.stop()
    -- print(profile.report(20))
end


--==========================#
-- = GAME LOOP
--=

function Game:update(dt)
    if IS_MOBILE or DEBUG.MOUSE_IS_FINGER then
        lovepad:update()
    end
    --=
    local e_hero = self.e_hero
    if not self.ai_enabled and e_hero and e_hero.c_state_machine:is(St_GoNextLvl) then
        if e_hero.c_state_machine:get().on_landing then
            self.ai_enabled = true
        end
    end
    --=
    S_PadListener:update()
    --=
    S_IsGuarding:update(dt)
    if self.ai_enabled then
        S_Ai:update(dt)
    end
    -- S_Ai2:update(dt)
    S_BombSolver:update(dt)
    --=
    S_Physic:update(dt)
    S_Collision:update(dt)
    S_EnemyCollision:update(dt)
    S_UpdateBumpPosition:update(dt)
    --=
    S_StateMachineUpdate:update(dt)
    S_StateMachineSetNewState:update(dt)
    --=
    S_Animate_Hero_Atlas:update(dt)
    S_Animate_Enemy_Atlas:update(dt)
    S_Animate_Fx:update(dt)
    S_BlinkUpdate:update(dt)
    S_UpdateScoreText:update(dt)
    --=
    self.tiny_world:update()
    --=
    S_OldPadUpdater:update()

    self.cam:update(dt)

    self.evt.on_game_over = false
    if self.e_hero.c_health.hp == 0 and not self.evt.on_game_over_trg then
        self.evt.on_game_over = true
        self.evt.on_game_over_trg = true
    end
    --===== ON ENEMY DEAD =====--
    for i, e_en in ipairs(self.e_enemies) do
        if e_en.c_health.hp == 0 and not e_en:has_active('c_anim') then
            if not e_en.c_b.is_outbouds then
                -- = LOOT 
                local loot_probas = {Life_Up_Sm=4, Life_Up_Md=2, Jewel=54}
                local loot_rand = love.math.random(1, 100)
                local loot_key = nil
                local p = 0
                for key, proba in pairs(loot_probas) do
                    p = p + proba
                    if loot_rand <= p then
                        loot_key = key
                        break
                    end
                end

                local loot_x = e_en.c_b:mid_x()
                local loot_y =  e_en.c_b:mid_y()

                if loot_key == 'Life_Up_Sm' then
                    self:add_e( E_LifeUp(loot_x, loot_y, E_LifeUp.Size.Sm) )
                elseif loot_key == 'Life_Up_Md' then
                    self:add_e( E_LifeUp(loot_x, loot_y, E_LifeUp.Size.Md) )
                elseif loot_key == 'Jewel' then
                    if e_en.jewel_color ~= nil then
                        self:add_e(  E_Jewel(loot_x, loot_y, e_en.jewel_color) )
                    end
                end
            end
            self.level_enemy_cnt = self.level_enemy_cnt - 1
            if e_en.c_ai.e_chase_flag then
                self:del_e(e_en.c_ai.e_chase_flag)
            end
            table.remove(self.e_enemies, i)
            self:del_e(e_en)
        end
    end

    self.on_lvl_clear = false
    if self.level_enemy_cnt == 0 and not self.on_lvl_clear_trg then
        self.on_lvl_clear = true
        self.on_lvl_clear_trg = true
        GameSignal:levelClear()
    end

    if self.level_enemy_cnt == 0 then
        self.is_lvl_clear = true
    end

    -- --=
    for i, e in ipairs(self.__todel) do
        self.tiny_world:removeEntity(e)
        if e.c_b and e.active then
            self.bump_world:remove(e)
        end
        e.active = false
        self.__todel[i] = nil
        -- table.remove(self.__todel, i)
    end

    for _, e in ipairs(self.__toadd) do
        self.tiny_world:addEntity(e)
    end

    self.tiny_world:refresh()
    self.__toadd = {}
    self.__todel = {}

    if self.e_hero.c_b:bot() > 0 then
        self.e_hero:off('c_pad')
        -- self.e_hero:off('c_move_hrz')
        self.e_hero.c_b.vx = 0
        -- self.e_hero.c_move_hrz.acc = self.e_hero.c_anim.dir * 124
    end

    if self.e_hero.c_b:bot() > self.ground.y and not self.hero_hit_ground_trigger then
        local h_x = self.e_hero.c_b:mid_x()

        self.e_hero.c_health:get_hit(10)
        self.e_hero.c_state_machine:set(St_HeroDead(self.e_hero))
        self.hero_hit_ground_trigger = true

        if  h_x < -96 or h_x > self.map.w + 96 then
            self.e_hero.c_b:set_bot(self.ground.y+8)
        else
            self.e_hero.c_b:set_bot(self.ground.y)
        end
        
        self.e_hero.c_b.vy = 0
    end

    self:evalGameOver()

    -- if self.on_lvl_clear then
    --     GAME.score = GAME.score + GAME.Score_Table.Level_Clear
    --     GAME:add_e( E_ScoreTxt(self.e_hero.c_b:mid_x(), self.e_hero.c_b:top()-4, GAME.Score_Table.Level_Clear, nil) )
    -- end

    -- = PARTICULE SYSTEMS 
    if self.is_lvl_loaded and self.level > 1 then
        self.psystem_level_clear:reset()
        self.psystem_level_clear:stop()
    end

    if self.is_lvl_clear then
        self.psystem_level_clear:start()
    end

    if self.is_lvl_clear then
        self.psystem_level_clear:moveTo(self.e_hero.c_b:mid_x()-9, self.e_hero.c_b:mid_y()-8)
        self.psystem_level_clear:update(dt)
    end

    self.psystem_blood:update(dt)
    self.psystem_blood:moveTo(self.e_hero.c_b:mid_x(), self.e_hero.c_b:mid_y())

    self:update_particle_systems(dt)
    -- Timer.update(dt)

    self.is_lvl_loaded = false

    self.game_ui:update(dt)

    self:updateMonkeyTimer(dt)
end


function Game:updateMonkeyTimer(dt)
     -- = MONKEY
     self.monkey_timer = self.monkey_timer + dt
     if self.monkey_timer > self.monkey_timeout then
         self.monkey_timer = 0
         -- = spawn monkey
         self:spawn_enemy(E_Enemy.Type.Monkey)
     end
end

function Game:scoreUp(points, spawn_x, spawn_y)
    spawn_x = spawn_x or self.e_hero.c_b:mid_x()
    spawn_y = spawn_y or self.e_hero.c_b:top() - 16

    self.score = self.score + points
    self:add_e( E_ScoreTxt(spawn_x, spawn_y, points) )
end

function Game:initScoreObserver()
    local Score_Table = self.Score_Table

    Signal.register('level-clear', function()
        self:scoreUp(Score_Table.Level_Clear)
    end)
    Signal.register('jewel-set-complete', function()
        self:scoreUp(Score_Table.Jewel_Set)
    end)
    Signal.register('jewel-collected', function(e_jewel)
        self:scoreUp(Score_Table.Jewel)
    end)
    Signal.register('enemy-killed', function(e_enemy)
        self:scoreUp(Score_Table[e_enemy.type], e_enemy.c_b:mid_x(), e_enemy.c_b:bot()-16)
    end)
end


function Game:evalGameOver()
    local e_hero = self.e_hero
    local e_monkeys = self.e_monkeys

    if e_hero.c_health.hp == 0 then
        if e_hero.c_state_machine:is(St_HeroDead) and e_hero.c_anim.is_over then
            self.is_game_over = true
        end
        for _, e_monkey in ipairs(e_monkeys) do
            local c_sm = e_monkey.c_state_machine
            if c_sm:is(St_MkGrabHero) and c_sm:get().is_game_over then
                self.is_game_over = true
            end
        end
    end
end


function Game:draw_camera_stuff()
    self = GAME
    

    self.parallax_z2:draw(function()
        local l, t, w, h = self.cam:getVisible()
        local pad = 30
        local img_h =  self.parallax_z2_img:getHeight()

        local var_x = l*0.9
        local var_y = t+h-img_h+pad+pad*0.4
        var_y = var_y - (t+h) / 800 * (pad+pad*0.4)

        self.parallax_z2:draw_tiled_single_axis(var_x, var_y, self.parallax_z2_img, 'x')
    end)

    self.parallax_z1:draw(function()
        local l, t, w, h = self.cam:getVisible()
        local pad = 200
        local img_h =  self.parallax_z1_img:getHeight()

        local var_x = l*0.8
        local var_y = t+h-img_h+pad+pad*0.6
        var_y = var_y - (t+h) / 800 * (pad+pad*0.6)

        self.parallax_z1:draw_tiled_single_axis(var_x, var_y, self.parallax_z1_img, 'x')
    end)    

    love.graphics.setColor(self.draw_color.map)
    self.map:draw()
    love.graphics.setColor(1,1,1,1)

    self.ground.parallaxs.road:draw(function()
        local y = self.ground.y
        self.ground.parallaxs.road:draw_tiled_single_axis(0, y, self.ground.road, 'x')
    end)

    self.ground.parallaxs.middle:draw(function()
        local quads = self.ground.quads

        local sw = 2 -- = sidewalk w
        local i_start = -sw-1
        local i_end = self.map.iw+sw

        for i=i_start, i_end  do
            local x = i * Tl.Dim
            local q = nil

            if i == i_start then
                q = quads.step_l
            elseif i == i_end then
                q = quads.step_r
            else
                q = quads.middle
            end
            love.graphics.draw(self.ground.tileset, q, x, self.ground.y)
        end
    end)
    
    self:drawDebugStuffs()
    
    S_DrawScoreText:update(love.timer.getDelta())
    S_Animate:update(love.timer.getDelta())

    -- = PARTICULES
    if self.is_lvl_clear then -- or self.psystem_level_clear:getCount() > 0 then
        love.graphics.draw(self.psystem_level_clear)
    end
    love.graphics.draw(self.psystem_blood)

    for type, psys_array in pairs(self.psystems) do
        for _, psys in ipairs(psys_array) do
            love.graphics.draw(psys.emitter)
        end
    end
    -- love.graphics.draw(self.psystem_item_picked_up)
end

function Game:drawDebugStuffs()
    -- = draw navigation map actions paths
    self.navmap:draw()
    -- = draw segments
    for _, seg in ipairs(self.__dbg_segments) do
        love.graphics.setColor(seg.color)
        love.graphics.setLineWidth(1)
        love.graphics.line(self.map.x + seg.x1, seg.y1, self.map.x + seg.x2, seg.y2)
    end
    -- = draw rectangles
    for _, rect in ipairs(self.__dbg_rects) do
        love.graphics.setColor(0,0,1)
        love.graphics.rectangle('line', self.map.x + rect.x1, rect.y1, rect.w, rect.h)
    end

    if DEBUG_HITBOX then
        S_DrawBodyOutline:update()
    end
    love.graphics.setColor(1,1,1)
end

function Game:draw()
    love.graphics.clear()
        -- love.graphics.setBackgroundColor(0.15, 0.5, 0.7, 0.5)
    self:draw_background()
    self.cam:draw(self.draw_camera_stuff)
    self.game_ui:draw()
    if IS_MOBILE or DEBUG.MOUSE_IS_FINGER then
        lovepad:draw()
    end
    self:drawProfilerReport()

end

function Game:add_e(e)
    if e then
        table.insert(self.__toadd, e)
    end
    return e
end

function Game:del_e(e)
    if e then
        table.insert(self.__todel, e)
    end
    return e
end

-- function Game:add_bezier_curve(vertices)
--     local bz_curve = love.math.newBezierCurve(vertices)

--     table.insert(self.__debug_bz_curves, bz_curve)
--     return bz_curve, #self.__debug_bz_curves
-- end

-- function Game:del_bezier_curve(index)
--     if self.__debug_bz_curves[index] then
--         self.__debug_bz_curves[index]:release()
--         self.__debug_bz_curves[index] = nil
--     end
--     -- table.remove(self.__debug_bz_curves, index)
-- end

function Game:rgb_to_factor(color)
    return {color[1] / 255, color[2] / 255, color[3] / 255}
end

function Game:draw_background()
    self.effect(function()
        love.graphics.setColor(GAME.draw_color.bg)
        love.graphics.draw(self.background_gradient, 0, 0, 0, love.graphics.getDimensions())
    end)
end

function Game:emit_blood(x, y, dir)
    self.psystem_blood:moveTo(x, y)
    self.psystem_blood:setOffset(0, 0)
    if dir == -1 then
        self.psystem_blood:setDirection( math.pi * 1.47 )
        self.psystem_blood:setLinearAcceleration(0, 400, 24, 500 )
    else
        self.psystem_blood:setDirection( math.pi * 1.53)
        self.psystem_blood:setLinearAcceleration(-24, 400, 0, 500 )
    end
    self.psystem_blood:emit(8)
end

function Game:update_particle_systems(dt)
    for _, psys_array in pairs(self.psystems) do
        for i, psys in ipairs(psys_array) do      
            psys.emitter:update(dt);
            if not psys.emitter:isActive() and not psys.timer_handle then
                local _, max_lt = psys.emitter:getParticleLifetime()
                psys.timer_handle = Timer.after(max_lt, function()
                    table.remove(psys_array, i)
                end)
            end
        end
    end
end

function Game:emit_pickable_particles(e_pickable)
    local psys = love.graphics.newParticleSystem( Spritesheet.Item_And_Fx, 50 )
    psys:setOffset(0, 0)
    psys:moveTo(
        self.e_hero.c_b:mid_x(),
        self.e_hero.c_b:bot()-8
    )
    -- if e_pickable:has('c_life_up') then
    --     psys:setColors(.5, .8, .4, 1)
    -- end
    psys:setParticleLifetime(0.3, 0.4)
	psys:setEmissionArea('borderellipse', 6, 4)
	psys:setEmissionRate(30)
	psys:setEmitterLifetime(0.15)
    psys:setSpeed(32, 64)
    psys:setDirection(-math.pi / 2)
    psys:setLinearAcceleration(0, -64, 0, -96)
    psys:setQuads(Atlas.Particle['spark_md'].quads)
    table.insert(self.psystems.pickable, {
        emitter=psys,
        timer_handle=nil
    })
end

function Game:emit_flare_particles(x, y)
    local psys = love.graphics.newParticleSystem( Spritesheet.Item_And_Fx, 16 )
    psys:setOffset(0, 0)
    psys:moveTo(x-24, y-24)
    psys:setParticleLifetime(0.3)
	psys:setEmissionArea('ellipse', 24, 24)
	psys:setEmissionRate(32)
	psys:setEmitterLifetime(0.4)
    psys:setSpeed(32, 64)
    psys:setQuads(Atlas.Fx['flare'].quads)
    table.insert(GAME.psystems.flare, {
        emitter=psys,
        timer_handle=nil
    })
end

function Game:emit_debris(x, y, normal_x)
    for i=1, 10 do
        local size = love.math.random(1, 10)
        local particule = E_Debris(x, y, size < 4 and 'md' or 'sm')

        particule.c_b.vy = -love.math.random(150, 240)
        particule.c_b.vx = love.math.random(0, 64) * normal_x
        self:add_e(particule)
    end
end

function Game:bombImpact(impact_x, impact_y)
    -- local radius = 32
    -- self:shockWave(impact_x, impact_y, radius, function(item)
    --     return Xtype.is(item, E_Actor)
    -- end, 1, 1)
    -- self:debugDrawRect(impact_x - radius, impact_y - radius, radius * 2, radius * 2, nil, 1)
    -- self.cam:shake(0.5, 12)
    local radius = 54

    self:shockWave(impact_x, impact_y, radius, function(item)
        return Xtype.is(item, E_Actor)
    end, 0.5, 1)
    self.cam:shake(0.5, 12)
end


function Game:rocketImpact(impact_x, impact_y)
--     local radius = 24
--     impact_y = impact_y -- offset

--     self:shockWave(impact_x, impact_y, radius, function(item)
--         return Xtype.is(item, E_Enemy)
--     end, 1.5, 1.5)
-- -- end, 0.6, 1.2)
--     -- self:debugDrawRect(impact_x - radius, impact_y - radius, radius * 2, radius * 2, nil, nil)
--     self.cam:shake(0.5, 12)
    local radius = 54

    self:shockWave(impact_x, impact_y, radius, function(item)
        return Xtype.is(item, E_Enemy)
    end, 0.5, 1)
    self.cam:shake(0.5, 12)
end

function Game:onEnemyThrowComboImpact(e_en)
    local radius = 20
    local impact_x = e_en.c_b:mid_x()
    local impact_y = e_en.c_b:bot() + 2

    self:shockWave(impact_x, impact_y, radius, function(item)
        return Xtype.is(item, E_Enemy) and item ~= e_en and item.is_hittable_by_thrown
    end, 0.6, 1.7)
end

function Game:heroLandImpact(impact_x, impact_y)
    local radius = 54

    self:shockWave(impact_x, impact_y, radius, function(item)
        return Xtype.is(item, E_Enemy)
    end, 0.5, 1)
    self.cam:shake(0.5, 12)
end

function Game:shockWave(impact_x, impact_y, radius, filter_func, sx, sy)
    local e_filtered, _ = GAME.bump_world:queryRect(
        impact_x-radius,
        impact_y-radius,
        radius*2,
        radius*2,
        filter_func
    )
    for _, e in ipairs(e_filtered) do
        local pow = self:getShockWavePow(impact_x, impact_y, radius, e)
        if pow then
            pow.x = pow.x * (sx or 1)
            pow.y = pow.y * (sy or 1)
            if Xtype.is(e, E_Enemy) then
                local hit_state = St_EnIsHit(e, pow.x, pow.y, false, true, false)
                e.c_state_machine:force_set(hit_state)
            end
            if Xtype.is(e, E_Hero) then
                local hit_state = St_HeroIsHit(e, pow.x, pow.y, false, true, false)
                e.c_state_machine:force_set(hit_state)
            end
        end
    end
end

function Game:getShockWavePow(impact_x, impact_y, radius, e)
    local dist = e.c_b:dist_to_xy(impact_x, impact_y)

    if dist < radius then
        local dx = e.c_b:mid_x() - impact_x
        local dy = e.c_b:mid_y() - impact_y

        local angle = math.atan2(dy, dx)
        local force = math.abs(1 - (dist / radius))

        if force > 0.6 then force = 0.6 end
        if force < 0.3 then force = 0.3 end
        -- print('cos', math.cos(angle), 'sin', math.sin(angle))
        local pow_x = math.cos(angle) * (700 * force)
        local pow_y = math.sin(angle) * (700 * force)

        if pow_y > -128 then 
            pow_y = -128
        end

        -- print('pow_x', pow_x, 'pow_y', pow_y, 'radian', angle, 'degree', angle*180/math.pi, 'force', force)
        if pow_x == 0 then
            pow_x = Tl.Dim
        end

        return V2(pow_x, pow_y)
    end

    return nil
end

function Game:getShockWavePow2(impact_x, impact_y, radius, e)
    local dist = e.c_b:dist_to_xy(impact_x, impact_y)

    if dist < radius then
        local dx = e.c_b:mid_x() - impact_x
        local dy = e.c_b:mid_y() - impact_y

        local angle = math.atan2(dy, dx)
        local force = math.abs(1 - (dist / radius))

        if force > 0.6 then force = 0.6 end
        if force < 0.3 then force = 0.3 end

        local pow_x = math.cos(angle) * (700 * force)
        local pow_y = math.sin(angle) * (700 * force)

        if pow_y > -128 then 
            pow_y = -128
        end

        -- print('pow_x', pow_x, 'pow_y', pow_y, 'radian', angle, 'degree', angle*180/math.pi, 'force', force)
        if pow_x == 0 then
            pow_x = Tl.Dim
        end

        return V2(pow_x, pow_y)
    end

    return nil
end

function Game:freeze_enemies() -- debug
    for i, e in ipairs(self.e_enemies) do
        e.c_anim:pause()
        e:off('c_move_hrz')
        e:off('c_ai')
    end
end

function Game:unfreeze_enemies() -- debug
    for i, e in ipairs(self.e_enemies) do
        e.c_anim:play()
        e:on('c_move_hrz')
        e:on('c_ai')
    end
end

function Game:freeze()
    self:freeze_enemies()
    self.e_hero.c_anim:pause()
    self.e_hero:off('c_move_hrz')
end

function Game:unfreeze()
    self:unfreeze_enemies()
    self.e_hero.c_anim:play()
    self.e_hero:on('c_move_hrz')
end

function Game:hit_wall(coll)
    local en = coll.item -- enemy
    local tl = coll.other
    local x = coll.normal.x == 1 and tl.c_b:right()+1 or tl.c_b:left()-2
    local y = en.c_b:mid_y()

    for i=1, 10 do

        local size = love.math.random(1, 10)
        local particule = E_Debris(x, y, size < 4 and 'md' or 'sm')

        particule.c_b.vy = -love.math.random(150, 240)
        particule.c_b.vx = love.math.random(0, 64) * coll.normal.x
        self:add_e(particule)
    end
end

function Game:hit_ceil(coll)
    local en = coll.item -- enemy
    local tl = coll.other
    local y = tl.c_b:bot()

    if en:has_active('c_gravity') then
        for i=1, 10 do

            local min_x = en.c_b:left()
            local max_x = en.c_b:right()
            local pad_x = (max_x - min_x)
            local rand_x = math.random(0, pad_x)
            local size = love.math.random(1, 10)
            local particule = E_Debris(min_x+rand_x, y, size < 4 and 'md' or 'sm')

            particule.c_b.vx = (-(pad_x * 0.5) + rand_x) * 10
            particule.c_b.vy = love.math.random(1, 6) * -32
            self:add_e(particule)
        end
    end
end

function Game:debugDrawSegment(x1, y1, x2, y2, --[[opt]] color, --[[opt]] ttl)
    local color = color or {0, 0, 1}
    local segment = {x1=x1, y1=y1, x2=x2, y2=y2, color=color}

    if not DEBUG_RECT then
        return
    end
    table.insert(self.__dbg_segments, segment)
    if ttl then
        Timer.after(ttl, function()
            self.__dbg_segments = table.filter(self.__dbg_segments, function(s)
                return s ~= segment
            end)
        end)
    end
end

function Game:debugDrawRect(x1, y1, w, h, --[[opt]] color, --[[opt]] ttl)
    local color = color or {0, 0, 1}
    local rect = {x1=x1, y1=y1, w=w, h=h, color=color}

    if not DEBUG_RECT then
        return
    end
    table.insert(self.__dbg_rects, rect)
    if ttl then
        Timer.after(ttl, function()
            self.__dbg_rects = table.filter(self.__dbg_rects, function(r)
                return r ~= rect
            end)
        end)
    end
end

return Game