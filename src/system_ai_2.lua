C_Ai2 = Class('C_Ai2', Comp)

function C_Ai2:__construct(e)
    Comp.__construct(self, e)
    -- = behaviour
    self.stance = 'wander' -- 'chase', 'wander'
    self.stance_timer = 0
    self.stance_timeout = S_Ai2:stanceTimeoutFormula()

    -- = navigation
    self.dir = nil
    self.tl_old = nil
    self.tl_cur = nil
    self.tl_bot = nil -- = tile below enemy feet
    self.tl_cur_progress = nil -- 0 <= x <= TILE_SIZE
    self.on_enter_tl = false

    self.step_sz = 16 -- = enter new step every x pixels
    self.step_cur = nil
    self.step_old = nil
    self.on_enter_step = false

    -- = hero related
    self.is_hero_left = false
    self.is_hero_right = false
    self.is_hero_up = false
    self.is_hero_down = false
    self.is_facing_hero = false

    self.is_hero_punchable = false
    self.is_hero_gunable = false
    self.is_hero_rocketable = false
    self.is_hero_katanable = false

    -- = ladder
    self.ladder_enabled = e.type ~= E_Enemy.Type.Ninja
    self.ladder_dir = nil

    -- = fall
    self.fall_enabled = e.type ~= E_Enemy.Type.Ninja
    self.fall_at = nil
    self.fall_dir = nil

    -- = jump
    self.jump_to = nil
    self.jump_streak = 0
    self.jump_shuriken_enabled = false
    
    -- = dash
    self.dash = false
    self.dash_turn_cnt = 0
    
    -- = bomb
    self.bomb = false
    self.bomb_enabled = false
end

function C_Ai2:setWanderStance()
    self.stance = 'wander'
    self.stance_timer = 0
    self.stance_timeout = S_Ai2:stanceTimeoutFormula()
end

function C_Ai2:setChaseStance()
    self.stance = 'chase'
    self.stance_timer = 0
    self.stance_timeout = S_Ai2:stanceTimeoutFormula()
end

function C_Ai2:setFallAtStance(nav_action)
    self.stance = 'fall_at'
    self.fall_at = nav_action.tl
    self.fall_dir = nav_action.dir
end

function C_Ai2:setIdleStance()
    self.stance = 'idle'
    self.stance_timer = 0
    self.stance_timeout = 2 + 4 * math.random()
end

--===========================#

S_Ai2 = Tiny.processingSystem()

S_Ai2.filter = Tiny.requireAll('c_b', 'c_ai', 'c_pad')
S_Ai2.active = false

S_Ai2.e_chasers = {}
S_Ai2.e_shooters = {}
S_Ai2.e_punchers = {}
S_Ai2.e_rocketers = {}
S_Ai2.e_katanas = {}
S_Ai2.e_bombers = {}

S_Ai2.bomb_cnt = 0

function S_Ai2:isFacingWall(e)
    local m =
        GAME.map
    local x =
        e.c_b:mid_x() + e.c_anim.dir * (e.c_b.w * .6)
    local y =
        e.c_b:mid_y()
    local e_tl =
        m:tile_at(x, y)

    if e_tl then
        return e_tl.c_tile:has_prop(Tl.Prop.Wall)
    else
        return false
    end
end

function S_Ai2:isFacingEdge(e)
    local m =
        GAME.map
    local goal_x =
        e.c_b:mid_x()
    local x2 =
        goal_x + e.c_ai.dir * (e.c_b.w * .6)
    local y =
        e.c_b:bot() + 2

    local e_tl_1 = m:tile_at(goal_x, y)
    local e_tl_2 = m:tile_at(x2, y)

    if e_tl_1 then
        return e_tl_1.c_tile:isEdge(-e.c_ai.dir) and 
            (e_tl_2 == nil or e_tl_2.c_tile:has_prop(Tl.Prop.Empty))
    else
        return true
    end
end

function S_Ai2:stanceTimeoutFormula()
    return 0.4 + math.random(0, 1) * math.random(1, 2)
end

function S_Ai2:isHeroInSight(e)
    -- = check each map tile between enemy and hero
    local e_hero = GAME.e_hero
    local m = GAME.map
    local goal_x = e.c_b:mid_x()
    local x2 = e_hero.c_b:mid_x()
    local x_min = math.min(goal_x, x2)
    local x_max = math.max(goal_x, x2)
    local x = x_min

    while x < x_max do
        local e_tl = m:tile_at(x, e.c_b:mid_y())
        -- = if tile is wall, return false
        if e_tl and e_tl.c_tile:has_prop(Tl.Prop.Wall) then
            return false
        end
        x = x + Tl.Dim
    end

    return true
end

function S_Ai2:isEnemyFacingHero(e)
    local e_hero = GAME.e_hero
    local dir = e.c_anim.dir
    -- if e.c_ai.dir ~= e.c_anim.dir then
    --     return false
    -- end
    
    if dir == 1 then
        -- print(e.c_ai.dir, e.c_b:mid_x() <= e_hero.c_b:mid_x())
        return e.c_b:mid_x() <= e_hero.c_b:mid_x()
    elseif dir == -1 then
        -- print(e.c_ai.dir, e.c_b:mid_x() > e_hero.c_b:mid_x())
        return e.c_b:mid_x() > e_hero.c_b:mid_x()
    end
    -- print('isEnemyFacingHero', e.c_ai.dir)
end

function S_Ai2:isHeroMeleable(e_en, range_min_x, range_max_x, range_min_y, range_max_y)
    local e_hero = GAME.e_hero
    local range_x = {min = range_min_x, max = range_max_x}
    local range_y = {min = range_min_y, max = range_max_y}

    local dist_x = e_en.c_b:mid_x() - e_hero.c_b:mid_x()
    local dist_y = e_en.c_b:bot() - e_hero.c_b:bot()

    local in_range_y = math.abs(dist_y) >= range_y.min and math.abs(dist_y) <= range_y.max
    local in_range_x = false
    
    if e_en.c_anim.dir == 1 and dist_x < 0 then
        in_range_x = 
            math.abs(dist_x) >= range_x.min and math.abs(dist_x) <= range_x.max 
    elseif e_en.c_anim.dir == -1 and dist_x > 0 then
        in_range_x = 
            math.abs(dist_x) >= range_x.min and math.abs(dist_x) <= range_x.max
    end

    return in_range_x and in_range_y
end

function S_Ai2:isHeroPunchable(e_en)
    local e_hero = GAME.e_hero
    local e_hero_csm = e_hero.c_state_machine
    local e_hero_status_ok = e_hero_csm:is(St_HeroGround)
        or e_hero_csm:is(St_ClimbPlatf)
        or e_hero_csm:is(St_Duck)
        or e_hero.is_guarding
    return self:isHeroMeleable(e_en, 8, 24, 0, 32) and e_hero_status_ok
end

function S_Ai2:isHeroKatanable(e_en)
    local e_hero = GAME.e_hero
    local e_hero_csm = e_hero.c_state_machine
    local e_hero_status_ok = e_hero_csm:is(St_HeroGround)
        or e_hero_csm:is(St_ClimbPlatf)
        or e_hero_csm:is(St_HangToPlatf)
        or e_hero_csm:is(St_Ladder)
        or e_hero_csm:is(St_Duck)
        or e_hero.is_guarding
    return self:isHeroMeleable(e_en, 16, 32, 0, 48) and e_hero_status_ok
end

function S_Ai2:isHeroGunnable(e, dist_x)
    local range_min = Tl.Dim * 1.5
    local in_range = dist_x > range_min

    return e:has('c_gun') and in_range and self:isEnemyFacingHero(e) and self:isHeroInSight(e)
end

function S_Ai2:isHeroRocketable(e, dist_x)
    local range_min = Tl.Dim * 3
    local in_range = dist_x > range_min

    return e:has('c_rocket') and in_range  and self:isEnemyFacingHero(e) and self:isHeroInSight(e)
end

function S_Ai2:ppBalanceBombers()
    local e_enemies = GAME.e_enemies
    local e_bombers = {}

    local e_hero = GAME.e_hero
    local e_bomber = nil

    -- = filter bombers
    e_bombers = table.filter(e_enemies, function(e)
        return e:has('c_bomb')
    end)
    -- = pick random bomber
    if #e_bombers > 0 then
        e_bomber = table.random(e_bombers) 
    end
    -- = if bomber
    if e_bomber then
        local is_position_valid = true
        local bomb_margin_min = 6
        local bomb_hero_min = Tl.Dim * 3
        
        local x = e_bomber.c_b:mid_x() - bomb_margin_min
        local y = e_bomber.c_b:mid_y()
        local w = bomb_margin_min * 2
        local h = Tl.Dim

        -- = check for collisions with bombs and ladders
        local _, len = GAME.bump_world:queryRect(x, y, w, h, function(item)
            local hovering_ladder = Xtype.is(item, E_Tile) and item.c_tile:has_prop(Tl.Prop.Ladder)
            local hovering_bomb = Xtype.is(item, E_Mine)
            
            return hovering_bomb or hovering_ladder
        end)
        
        -- = cannot place bombs too close to each other
        -- = cannot place bombs while hovering ladder 
        if len > 0 then
            is_position_valid = false
        -- = cannot place bombs too close to hero
        elseif e_bomber.c_b:dist_to(e_hero.c_b) < bomb_hero_min then
            is_position_valid = false
        end

        if is_position_valid and math.random(100) < 50 then
            e_bomber.c_ai.bomb_enabled = true
        else
            e_bomber.c_ai.bomb_enabled = false
        end
    end
end

function S_Ai2:ppBalanceMeleeAtkers(dt)
    local e_enemies = table.clone(GAME.e_enemies)
    local e_hero = GAME.e_hero
    local e_hero_sm = e_hero.c_state_machine


     -- = reset puncher candidates c_ai
     self.e_punchers = table.filter(self.e_punchers, function(e_en)
        local c_sm = e_en.c_state_machine
        if not c_sm:is(St_Punch) then
            e_en.c_ai.is_hero_punchable = false
            return false
        else
            return true
        end
    end)
    -- = reset katanas
    self.e_katanas = table.filter(self.e_katanas, function(e)
        local c_sm = e.c_state_machine
        if not c_sm:is(St_Katana) then
            e.c_ai.is_hero_katanable = false
            return false
        else
            return true
        end
    end)

    for i, e_en in ipairs(e_enemies) do
        
        if e_en:has_active('c_punch') and self:isHeroPunchable(e_en) then
            table.insert(self.e_punchers, e_en)
            e_en.c_ai.is_hero_punchable = true
        end

        if e_en:has_active('c_katana') and self:isHeroKatanable(e_en) then
            table.insert(self.e_katanas, e_en)
            e_en.c_ai.is_hero_katanable = true
        end
    end
end


-- = Balance Attackers (Punch, Gun, Rocket, Katana)
-- = Make sure there are not too many of each attacker

function S_Ai2:ppBalanceRangeAtkers(dt)
    local e_enemies = table.clone(GAME.e_enemies)
    local e_hero = GAME.e_hero
    local e_hero_sm = e_hero.c_state_machine

    -- = reset shooter candidates c_ai
    self.e_shooters = table.filter(self.e_shooters, function(e)
        local c_sm = e.c_state_machine
        if not c_sm:is(St_Gun) and not c_sm:is(St_GunDucked) then
            e.c_ai.is_hero_gunable = false
            return false
        else
            return true
        end
    end)
    -- = reset shooter candidates c_ai
    self.e_rocketers = table.filter(self.e_rocketers, function(e)
        local c_sm = e.c_state_machine
        if not c_sm:is(St_Rocket) then
            e.c_ai.is_hero_rocketable = false
            return false
        else
            return true
        end
    end)

    if
        not e_hero_sm:is(St_HeroGround) and 
        not e_hero_sm:is(St_ClimbPlatf) and
        not e_hero_sm:is(St_Duck) and
        not e_hero.is_guarding then
        return
    end

    -- = get y aligned enemies
    e_enemies = table.filter(e_enemies, function(e)
        if e_hero_sm:is(St_HangToPlatf) or e_hero_sm:is(St_ClimbPlatf) then
        --     -- print('St_HangToPlatf')
            return e.c_b:dist_to(e_hero.c_b) < 48
        else
            return e.c_b:is_y_aligned(e_hero.c_b)
        end
    end)
    -- = get closest enemy to hero from left and right
    local e_enemies_left = table.filter(e_enemies, function(e)
        return e.c_b:mid_x() < e_hero.c_b:mid_x()
            and not e.is_guarding
    end)

    local e_enemies_right = table.filter(e_enemies, function(e)
        return e.c_b:mid_x() > e_hero.c_b:mid_x()
            and not e.is_guarding
    end)

    local e_closest_left = table.min(e_enemies_left, function(e)
        return e.c_b:dist_to(e_hero.c_b)
    end)

    local e_closest_right = table.min(e_enemies_right, function(e)
        return e.c_b:dist_to(e_hero.c_b)
    end)

    -- = collect closest enemy candidates
    local e_candidates = {}

    if e_closest_left and e_closest_left.c_anim.dir == 1 then
        table.insert(e_candidates, e_closest_left)
    end

    if e_closest_right and e_closest_right.c_anim.dir == -1 then
        table.insert(e_candidates, e_closest_right)
    end

    for _, e in ipairs(e_candidates) do

        local dist_x = math.abs( e.c_b:dist_x(e_hero.c_b) )
        -- = GUN
        if self:isHeroGunnable(e, dist_x) then
            e.c_ai.is_hero_gunable = true
            table.insert(self.e_shooters, e)

        -- = ROCKET
        elseif self:isHeroRocketable(e, dist_x) then
            e.c_ai.is_hero_rocketable = true
            table.insert(self.e_rocketers, e)
        end
    end
end

function S_Ai2:ppBalanceChasers(dt)

    local e_enemies = table.clone(GAME.e_enemies)
    local e_hero = GAME.e_hero

    -- = sort enemies by closest to hero first
    table.sort(e_enemies, function(a, b)
        local dist_a = a.c_b:dist_to(e_hero.c_b)
        local dist_b = b.c_b:dist_to(e_hero.c_b)
        return dist_a < dist_b
    end)

    -- = filter the n closest enemies
    local n_closest = 4--math.floor(2 + GAME.level_enemy_cnt / 4)
    local e_enemies = table.slice(e_enemies, 1, n_closest)

    -- = pick n different enemies at random to chase hero
    local n = 3
    local e_updated = {}
    for i = 1, n do
        local e = table.remove(e_enemies, math.random(1, #e_enemies))
        table.insert(e_updated, e)
    end

    -- = We only update stances of randomly picked enemies closest to hero 
    -- = so some enemies will be left "wandering" or "chasing"
    -- = until they get close enough be picked again at random
    -- = which is fine, it's more natural and less predictable
    for _, e in ipairs(e_updated) do
        local c_ai = e.c_ai

        if c_ai.stance == 'fall_at' then
            if not e.c_state_machine:is(St_EnGround) then
                c_ai.stance = 'wander'
            end
        end

        if c_ai.stance == 'shuriken' then
            if not e.c_state_machine:is(St_Shuriken) then
                c_ai.stance = 'chase'
            end
        end

        if c_ai.stance == 'idle' then
            if c_ai.stance_timer > c_ai.stance_timeout then
                c_ai:setWanderStance()
            else
                c_ai.stance_timer = c_ai.stance_timer + dt
                return
            end
        end

        if c_ai.stance == 'wander' then
            c_ai.stance_timer = c_ai.stance_timer + dt
            
            if c_ai.stance_timer > c_ai.stance_timeout then
                c_ai:setChaseStance()
                table.insert(self.e_chasers, #self.e_chasers + 1, e)
            end
        end

        if c_ai.stance == 'chase' then -- and update_stance then
            c_ai.stance_timer = c_ai.stance_timer + dt
            
            if c_ai.stance_timer > c_ai.stance_timeout then
                c_ai:setWanderStance()
                table.remove_by_value(self.e_chasers, e)
            end
        end
    end

    -- = if there are too many chasers, remove one at random
    if #self.e_chasers > 4 then
        local e = table.remove(self.e_chasers, math.random(1, #self.e_chasers))
        e.c_ai.stance = 'wander'
    end
end

-- = Comportement de groupe
function S_Ai2:preProcess(dt)
    self:ppBalanceMeleeAtkers()
    self:ppBalanceRangeAtkers()
    self:ppBalanceBombers()
    self:ppBalanceChasers(dt)
end

-- = Comportement individuel
-- = 2 sources de comportement : c_ai.stance & c_sm.state
function S_Ai2:process(e, dt)
    local c_sm = e.c_state_machine
    local c_ai = e.c_ai
    local c_pad = e.c_pad
    local m = GAME.map

    if true then
        -- return
    end

    -- = reset actions that can be performed by any enemy
    c_ai.jump_to = nil -- E_Tile
    c_ai.punch = false
    c_ai.katana = false
    c_ai.shuriken = false
    c_ai.gun = false
    c_ai.rocket = false
    c_ai.turn = false
    c_ai.dash = false
    c_ai.bomb = false
    c_ai.claw = false
    c_ai.grab_hero = false
    c_ai.dir = nil

    c_ai.tl_cur =
        m:tile_at(e.c_b:mid_x(), e.c_b:mid_y())
    c_ai.tl_bot =
        m:tile_at(e.c_b:mid_x(), e.c_b:bot() + 2)

    c_ai.step_cur =
        math.floor(e.c_b:mid_x() / c_ai.step_sz)
    c_ai.on_enter_step =
        c_ai.step_cur ~= c_ai.step_old

    c_ai.tl_cur_progress = nil

    if c_ai.tl_cur then

        if e.c_anim.dir == 1 then
            c_ai.tl_cur_progress =
                e.c_b:mid_x() - c_ai.tl_cur.c_b:left()
        else
            c_ai.tl_cur_progress =
                c_ai.tl_cur.c_b:right() - e.c_b:mid_x()
        end
    end
    -- c_ai.stance = 'chase'
    self:collectHeroData(e)

    if c_sm:is(St_EnGround) then
        self:onGroundState(e, dt)
    end

    if e.type == E_Enemy.Type.Ninja then
        self:onNinjaType(e, dt)
    elseif e.type == E_Enemy.Type.Monkey then
        self:onMonkeyType(e, dt)
    elseif Xtype.is(e, E_BaseSoldier) then
        self:onSoldierType(e, dt)
    end

    -- c_ai.dir = e.c_anim.dir

    if c_ai.turn and e.c_ai.dir == -1 then
        c_ai.dir = 1
    elseif c_ai.turn and e.c_ai.dir == 1 then
        c_ai.dir = -1
    end

    -- = action to perform turned into pad input 
    -- = with concerns for priority
    if e.c_ladder and c_ai.ladder_dir == -1 then
        c_pad:press('up')
    elseif e.c_ladder and c_ai.ladder_dir == 1 then
        c_pad:press('down')
    elseif c_ai.fall_action then
        c_ai:setFallAtStance(c_ai.fall_action)
        c_ai.fall_action = nil
    elseif c_ai.punch then
        c_pad:press('punch')
    elseif c_ai.katana then
        c_pad:press('katana')
    elseif c_ai.gun then
        -- = une chance sur deux de tirer en duck
        c_pad:press(math.random(1, 2) == 1 and 'gun_duck' or 'gun')
    elseif c_ai.rocket then
        c_pad:press('rocket')
    elseif c_ai.jump_to then
        if e.type == E_Enemy.Type.Ninja then
            c_sm:set(St_NinjaJump(e, c_ai.jump_to))
            -- e.c_ai.stance = 'wander'
        else
            c_sm:set(St_Jump(e, c_ai.jump_to))
        end
    elseif c_ai.shuriken then
        -- c_pad:press('shuriken')
    elseif c_ai.dash then
        c_pad:press('dash')
    elseif e.c_grab_hero and c_ai.grab_hero then
        c_pad:press('grab_hero')
    elseif c_ai.claw then
        c_pad:press('claw')
    elseif c_ai.bomb then
        c_pad:press('bomb')
        c_ai.bomb_enabled = false
    elseif c_ai.dir == 1 then
        c_pad:press('right')
    elseif c_ai.dir == -1 then
        c_pad:press('left')
    end

    -- print(e.c_b.vx)
    -- print(c_ai.dir )


    c_ai.tl_old = c_ai.tl_cur
    c_ai.step_old = c_ai.step_cur
end

function S_Ai2:onGroundState(e, dt)
    local c_ai = e.c_ai
    local turn_at_edge = true

    c_ai.dir = e.c_anim.dir
    c_ai.ladder_dir = nil

    if c_ai.stance == 'chase' then
        if e.type == E_Enemy.Type.Ninja then
            self:ninjaChase(e, dt)
        elseif e.type == E_Enemy.Type.Monkey then
            self:monkeyChase(e, dt)
        else
            self:militaryChase(e, dt)
        end
    elseif c_ai.stance == 'fall_at' then
        turn_at_edge = false
        c_ai.dir = c_ai.fall_dir
    elseif c_ai.stance == 'idle' then
        c_ai.dir = 0
    end

    c_ai.isFacingWall = self:isFacingWall(e)
    c_ai.isFacingEdge = self:isFacingEdge(e)

    if c_ai.isFacingWall then
        c_ai.turn = true
    end

    if c_ai.isFacingEdge and turn_at_edge then
        c_ai.turn = true
    end
    -- print('la', c_ai.is_hero_punchable)
    if c_ai.is_hero_punchable then
        -- = check if hero hitbox is in front of enemy
        c_ai.punch = true

    elseif c_ai.is_hero_katanable then
        -- print('katana')
        c_ai.katana = true
    end
end

function S_Ai2:collectHeroData(e)
    local e_hero = GAME.e_hero
    local c_ai = e.c_ai
    local m = GAME.map

    local hero_ix, hero_iy = m:cooToIndex(e_hero.c_b:mid_x(), e_hero.c_b:mid_y())
    local enemy_ix, enemy_iy = m:cooToIndex(e.c_b:mid_x(), e.c_b:mid_y())

    c_ai.is_hero_aligned = hero_iy == enemy_iy
    -- = is hero right/left/up/down of enemy
    c_ai.is_hero_left =
        e_hero.c_b:mid_x() < e.c_b:mid_x()
    c_ai.is_hero_right =
        e_hero.c_b:mid_x() > e.c_b:mid_x()
    c_ai.is_hero_up =
        e_hero.c_b:bot() < e.c_b:bot()
    c_ai.is_hero_down =
        e_hero.c_b:bot() > e.c_b:bot()

    -- = is hero in front of enemy
    c_ai.is_facing_hero =
        (e.c_anim.dir == 1 and c_ai.is_hero_right) or
        (e.c_anim.dir == -1 and c_ai.is_hero_left)

    -- = has enemy changed tile
    c_ai.on_enter_tl =
        e.c_ai.tl_old ~= e.c_ai.tl_cur

    -- = distance to hero
    c_ai.hero_dist_x =
        math.abs(e_hero.c_b:mid_x() - e.c_b:mid_x())
    c_ai.hero_dist_y =
        math.abs(e_hero.c_b:mid_y() - e.c_b:mid_y())
    c_ai.hero_dist = 
        e_hero.c_b:dist_to(e.c_b)

    -- = direction to hero
    c_ai.hero_dx =
        e_hero.c_b:mid_x() > e.c_b:mid_x() and 1 or -1
    c_ai.hero_dy =
        e_hero.c_b:mid_y() > e.c_b:mid_y() and 1 or -1

        
end


function S_Ai2:militaryChase(e, dt)

    local c_ai = e.c_ai

    local ladder_enabled = c_ai.tl_cur
        and not e.is_carrying_hero
        and c_ai.tl_cur_progress > 10 and c_ai.tl_cur_progress < Tl.Dim - 10

    local is_hovering_ladder_up = c_ai.tl_cur
        and ladder_enabled
        and c_ai.tl_cur.c_tile:has_prop(Tl.Prop.Ladder)

    local is_hovering_ladder_down = c_ai.tl_bot
        and ladder_enabled
        and c_ai.tl_bot.c_tile:has_prop(Tl.Prop.Ladder)

    local fall_enabled = not e.is_carrying_hero
    local is_jump_allowed = not e.is_carrying_hero

    -- = turn towards hero
    if c_ai.on_enter_tl then

        if c_ai.is_hero_left and c_ai.dir == 1 then
            c_ai.turn = true

        elseif c_ai.is_hero_right and c_ai.dir == -1 then
            c_ai.turn = true
        end
    end

    -- = use ladder
    if c_ai.ladder_enabled then

        if c_ai.is_hero_up and is_hovering_ladder_up then
            c_ai.ladder_dir = -1
        elseif c_ai.is_hero_down and is_hovering_ladder_down then
            c_ai.ladder_dir = 1
        end
    end

    -- = drop bomb on ground
    if c_ai.bomb_enabled and c_ai.on_enter_step then
        c_ai.bomb = true
    end

    -- = jump or fall
    local nav_tl = GAME.navmap:tile_at(e.c_b:mid_x(), e.c_b:mid_y())
    local nav_actions = {}

    if (fall_enabled or is_jump_allowed) and nav_tl and c_ai.on_enter_step then

        if c_ai.is_hero_up then
            nav_actions = nav_tl.up
        elseif c_ai.is_hero_down then
            nav_actions = nav_tl.down
        end

        local jump_actions = {}
        local fall_actions = {}

        local temp = {}
        for _, action in ipairs(nav_actions) do

            if action.type == NavAction.Type.Jump then
                table.insert(temp, action)
                table.insert(jump_actions, action)
            end

            if action.type == NavAction.Type.Fall then
                table.insert(temp, action)
                table.insert(fall_actions, action)
            end
        end
        nav_actions = temp

        -- = ninja might dash if no jump action is available
        -- if #jump_actions == 0 and e.type == E_Enemy.Type.Ninja then
        --     c_ai.dash = true
        -- end

        c_ai.nav_actions = nav_actions
        c_ai.jump_actions = jump_actions
        c_ai.fall_actions = fall_actions

        if #nav_actions > 0 then

            -- = action aléatoire
            local action = nav_actions[math.random(1, #nav_actions)]

            -- 1 chance sur 2 de jump, 1 chance sur 2 de fall
            if #fall_actions > 0 and #jump_actions > 0 then
                if math.random (1, 2) == 1 then
                    action = c_ai.jump_actions[math.random(1, #c_ai.jump_actions)]
                else
                    action = fall_actions[math.random(1, #fall_actions)]
                end
            end

            -- = action choisie
            if action.type == NavAction.Type.Jump then
                c_ai.jump_to = action.dest.tl

            elseif action.type == NavAction.Type.Fall then
                c_ai.fall_action = action
            end
        end
    end

    -- = GUN
    if c_ai.on_enter_step and not c_ai.turn and c_ai.is_hero_gunable then
        c_ai.gun = true

    -- = ROCKET
    elseif c_ai.on_enter_tl and not c_ai.turn and c_ai.is_hero_rocketable then
        c_ai.rocket = true
    end
end


function S_Ai2:ninjaChase(e, dt)
    local e_hero = GAME.e_hero
    local c_ai = e.c_ai

    local m = GAME.map

    local hero_ix, hero_iy = m:cooToIndex(e_hero.c_b:mid_x(), e_hero.c_b:mid_y())
    local enemy_ix, enemy_iy = m:cooToIndex(e.c_b:mid_x(), e.c_b:mid_y())

    -- = turn towards hero
    local is_hero_up = hero_iy < enemy_iy
    local is_hero_down = hero_iy > enemy_iy
    if c_ai.on_enter_tl then

        if c_ai.is_hero_left and c_ai.dir == 1 then
            c_ai.turn = true

        elseif c_ai.is_hero_right and c_ai.dir == -1 then
            c_ai.turn = true
        end
    end

    -- = exit if conditions are not met
    if not c_ai.on_enter_step or e.c_state_machine:is(St_NinjaJump) or e.c_state_machine:is(St_NinjaDash) then
        return
    end
    -- = try to dash
    if c_ai.on_enter_step and math.random(1, 100) < 10 then
        c_ai.dash = true
        return
    end
    -- = collect jump targets
    local is_hero_aligned = hero_iy == enemy_iy

    local jump_targets = {}
    local jump_verts = {}

    -- = get jump targets from navmap (jump up and down)
    local nv_tl = GAME.navmap:tile_at(e.c_b:mid_x(), e.c_b:mid_y())
    local nv_actions = {}

    if is_hero_up or is_hero_aligned then
        nv_actions = nv_tl.up
    elseif is_hero_down then
        nv_actions = nv_tl.down
    end
    -- = filter ladder actions
    for _, action in ipairs(nv_actions) do
        if action.dest then
            local t = action.type
            if t == NavAction.Type.Jump or t == NavAction.Type.Fall then
                table.insert(jump_verts, action.dest.tl)
            end
        end
    end
    -- = collect jump targets around ninja
    local tl_1, tl_4, tl_5 = nil, nil, nil
    if is_hero_aligned then

        tl_1 = nil -- jump to hero
        tl_4 = nil -- jump over hero
        tl_5 = nil -- jump backwards

        -- = jump to hero
        tl_1 = m:getNextGroundTile(hero_ix - math.random(-2, 2), hero_iy)

        if tl_1 then
            table.insert(jump_targets, tl_1)
        end
        -- = jump over hero
        if c_ai.is_hero_left then
            local ix = hero_ix - (enemy_ix - hero_ix)
            tl_4 = m:getNextGroundTile(ix, hero_iy)
        elseif c_ai.is_hero_right then
            local ix = hero_ix + (hero_ix - enemy_ix)
            tl_4 = m:getNextGroundTile(ix, hero_iy)
        end

        if tl_4 then
            table.insert(jump_targets, tl_4)
        end
        -- = jump backwards
        if c_ai.is_facing_hero then
            tl_5 = m:getNextGroundTile(enemy_ix - c_ai.dir * 2, hero_iy)
        end

        if tl_5 then
            table.insert(jump_targets, tl_5)
        end
    end

    -- = filter jump targets
    local filtered = {}
    local max_range = Tl.Dim * 6
    for i, e_tl in ipairs(jump_targets) do
        local filter = false
        -- = don't jump onto hero
        if e_tl.ix == enemy_ix and e_tl.iy == enemy_iy then
            filter = true
        end
        -- = don't jump to far
        if e_tl.c_b:dist_to(e.c_b) > max_range then
            filter = true
        end

        if not filter then
            table.insert(filtered, e_tl)
        end
    end
    jump_targets = filtered
    -- = pick a jump target at random 
    -- = either from jump_targets or jump_verts
    if math.random(1, 2) == 1 and #jump_targets > 0 then
        local jump_tl = jump_targets[math.random(1, #jump_targets)]
       
        -- = check if jump crosses WALL
        if self:isValidJumpTile(e, jump_tl) then 
            c_ai.jump_to = jump_tl
           -- = no shuriken if getting close to hero
            c_ai.jump_shuriken_enabled = jump_tl ~= tl_1 and jump_tl ~= tl_4
        end

    elseif #jump_verts > 0 then

        local jump_vert = jump_verts[math.random(1, #jump_verts)]
        -- = navmap targets are always valid
        c_ai.jump_to = jump_vert

        if c_ai.is_hero_down then
            c_ai.jump_shuriken_enabled = false
        else
            c_ai.jump_shuriken_enabled = true
        end
    end
end

function S_Ai2:onNinjaType(e, dt)
    local c_ai = e.c_ai
    local c_sm = e.c_state_machine
    local c_st = c_sm:get()
    local e_hero = GAME.e_hero

    if c_sm:is(St_NinjaJump) then
        local kinematic_jump = c_st.kinematic_jump
        local shuriken_range_min = Tl.Dim * 2

        if c_st.is_on_enter then
            local is_range_ok = e.c_b:dist_to(e_hero.c_b) > shuriken_range_min

            c_ai.jump_streak = c_ai.jump_streak + 1
            if c_ai.jump_streak == 1 and c_ai.jump_shuriken_enabled then
                c_ai.shoot_shuriken = math.random(1, 1) == 1 and is_range_ok
            else
                c_ai.shoot_shuriken = false
            end
        end

        if c_st.is_on_update then
            local jump_dy = kinematic_jump.dir_y

            local is_valid_x = math.abs(e.c_b:mid() - c_st.goal_x) < 16
            local is_valid_y = nil
            local is_valid_goal_y = e.c_b:mid_y() < c_st.goal_y - 32

            if jump_dy == -1 then
                is_valid_y = (is_valid_goal_y) and (c_ai.is_hero_down)
            elseif jump_dy == 1 and c_st.from_y == c_st.goal_y then
                is_valid_y = (is_valid_goal_y) and (c_ai.is_hero_down) and (kinematic_jump:getProgressToZenith(c_st.timer) > 80)
            end

            if c_ai.shoot_shuriken and is_valid_x and is_valid_y then
                c_ai.shuriken = true
                c_ai.stance = 'shuriken'
            end

            if c_st.on_landing then
                c_ai.jump_streak = c_ai.jump_streak - 1
                e.c_anim.dir = c_ai.is_hero_right and 1 or -1
                c_ai.stance = 'wander'
            end
        end
    end

    if c_sm:is(St_NinjaDash) then

        if c_st.is_on_enter then
            c_ai.dash_turn_cnt = 0
        end

        self:onGroundState(e, dt)

        if c_ai.stance == 'chase' then

            if c_ai.on_enter_tl and math.random(1, 100) < 25 then
                if c_ai.is_hero_left then
                    e.c_anim.dir = -1
                else
                    e.c_anim.dir = 1
                end
            end
        end

        if c_ai.turn then
            c_ai.dash_turn_cnt = c_ai.dash_turn_cnt + 1
            if c_ai.dash_turn_cnt > 2 then
                c_sm:set(St_EnGround(e))
            end
        end

        if c_ai.on_enter_tl and math.random(1, 100) < 10 then
            c_sm:set(St_EnGround(e))
        end

    end
end

function S_Ai2:isValidJumpTile(e, e_tl)
    local n_segments = 2 -- = precision

    local from_x, from_y = e.c_b:mid_x(), e.c_b:bot()
    local from_ix, from_iy = GAME.map:cooToIndex(from_x, from_y)

    local goal_x, goal_y = e_tl.c_b:mid_x(), e_tl.c_b:mid_y()
    local goal_ix, goal_iy = nil, nil

    local kinematic_jump = KinematicJump()
    kinematic_jump:init(from_x, from_y, goal_x, goal_y)

    for i = 1, n_segments do
        local timer = (i / n_segments) * kinematic_jump.t

        goal_x, goal_y = kinematic_jump:getPos(timer)
        goal_ix, goal_iy = GAME.map:cooToIndex(goal_x, goal_y)

        local res = Bresenham.los(from_ix, from_iy, goal_ix, goal_iy, function(ix,iy)
            if GAME.map:isSolidAtIndex(ix, iy) then
                return false
            end
            return true
        end)
        if res == false then
            return false
        end
        from_ix, from_iy = goal_ix, goal_iy
    end
    return true
end

function S_Ai2:monkeyTryMelee(e)
    local x, y = nil, e.c_b:mid_y()
    local w, h = 10, 6

    if e.c_anim.dir == -1 then
        x = e.c_b:mid_x() - w
    else
        x = e.c_b:mid_x()
    end
    local _, len = GAME.bump_world:queryRect(x, y, w, h, function(item)
        return Xtype.is(item, E_Hero)
    end)
    if len > 0 then
        e.c_ai.claw = true
    end
end

function S_Ai2:monkeyTryGrabHero(e)
    local x, y = nil, e.c_b:mid_y()
    local w, h = 10, 6

    if e.c_anim.dir == -1 then
        x = e.c_b:mid_x() - w
    else
        x = e.c_b:mid_x()
    end
    local _, len = GAME.bump_world:queryRect(x, y, w, h, function(item)
        return Xtype.is(item, E_Hero)
    end)
    return len > 0
end

function S_Ai2:monkeyTryDestroyTile(e)
    if e.c_b.is_on_ground or e.c_b.has_hit_ground then
        return
    end

    local x, y = e.c_b:left(), e.c_b:top()
    local w, h = e.c_b.w, e.c_b.h

    local e_tiles, len = GAME.bump_world:queryRect(x, y, w, h, function(item)
        return Xtype.is(item, E_Tile) and item.c_tile:has_prop(Tl.Prop.Wall)
    end)
    for i = 1, len do
        local e_tile = e_tiles[i]
        GAME.map:destroy_tile(e_tile.ix, e_tile.iy, -e.c_anim.dir)
    end
end


function S_Ai2:monkeyChase(e)
    local m = GAME.map
    local e_hero = GAME.e_hero
    local c_ai = e.c_ai
    -- = melee atk
    self:monkeyTryMelee(e)
    -- = turn towards hero
    local hero_ix, hero_iy = m:cooToIndex(e_hero.c_b:mid_x(), e_hero.c_b:mid_y())
    local _, enemy_iy = m:cooToIndex(e.c_b:mid_x(), e.c_b:mid_y())

    if c_ai.on_enter_tl then
        c_ai.turn = 
            (c_ai.is_hero_left and c_ai.dir == 1) or
            (c_ai.is_hero_right and c_ai.dir == -1)
    end

    -- if self:monkeyTryGrabHero(e) then
    --     c_ai.grab_hero = true
    -- end
    -- = exit if conditions are not met
    if not c_ai.on_enter_step then
        return
    end

    if math.random(100) < 10 and not c_ai.is_hero_aligned then
        c_ai:setIdleStance()
        c_ai.dir = 0
        return
    end

    -- = collect jump targets
     local is_hero_up = hero_iy < enemy_iy
     local is_hero_down = hero_iy > enemy_iy

     local jump_targets = {}
     local jump_verts = {}
 
     -- = get jump targets from navmap (jump up and down)
     local nv_tl = GAME.navmap:tile_at(e.c_b:mid_x(), e.c_b:mid_y())
     local nv_actions = {}
 
     if is_hero_up then
         nv_actions = nv_tl.up
     elseif is_hero_down then
         nv_actions = nv_tl.down
     end
     -- = filter ladder actions
     for _, action in ipairs(nv_actions) do
        if action.dest then
            local t = action.type
            if t == NavAction.Type.Jump or t == NavAction.Type.Fall then
                table.insert(jump_verts, action.dest.tl)
            end
        end
    end
    -- = jump to hero
    local tl_1 = m:getNextGroundTile(hero_ix, hero_iy)
    if tl_1 then
        local dist = tl_1.c_b:dist_to(e.c_b)
        if dist > Tl.Dim * 2 then
            table.insert(jump_targets, tl_1)
        end
    end
     -- = pick a jump target at random 
     -- = either from jump_targets or jump_verts
    if math.random(1, 2) == 1 and #jump_targets > 0 then
        local jump_tl = jump_targets[math.random(1, #jump_targets)]
        c_ai.jump_to = jump_tl
        GAME.cam:shake(0.2, 6)

    elseif #jump_verts > 0 then
         local jump_vert = jump_verts[math.random(1, #jump_verts)]
         c_ai.jump_to = jump_vert
    end
end

function S_Ai2:onSoldierType(e, dt)
    local c_sm = e.c_state_machine
    local c_st = c_sm:get()

    if c_sm:is(St_Jump) and c_st.is_on_update then
        if c_st.on_landing then--and math.random(100) > 50 then
            e.c_anim.dir = e.c_ai.is_hero_right and 1 or -1
        end
    end
end

function S_Ai2:onMonkeyType(e, dt)
    local c_ai = e.c_ai
    local c_sm = e.c_state_machine
    local c_st = c_sm:get()
    local e_hero = GAME.e_hero

    if c_sm:is(St_Jump) then

        if c_st.is_on_enter then

        end

        if c_st.is_on_update then

            if not c_st.on_landing then
                self:monkeyTryDestroyTile(e)
            end

            if math.random(1) == 1 and self:monkeyTryGrabHero(e) then
                c_ai.grab_hero = true
            else
                self:monkeyTryMelee(e)
            end
        end
    end
end