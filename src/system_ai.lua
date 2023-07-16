local Tiny = Tiny or require 'tiny'
local Bresenham = Bresenham or require 'bresenham'
local KinematicJump = KinematicJump or require 'kinematic_jump'

C_Ai = Class('C_Ai', Comp)

function C_Ai:__construct(e)
    Comp.__construct(self, e)
    -- = behaviour
    self.stance = nil
    self:setWanderStance()

    -- = navigation
    self.old_tile = nil
    self.cur_tile = nil
    self.bot_tile = nil -- = tile below enemy feet

--     self.tl_cur_progress = nil -- 0 <= x <= TILE_SIZE
    self.on_enter_tile = false

    -- = enter new step every "step_size" pixels
    self.step_size = 16
    self.cur_step = nil
    self.old_step = nil
    self.on_enter_step = false

    self.bomb_cooldown = 4

    -- = ninja jump
    self.jump_streak = 0
    self.jump_shuriken_enabled = false
    
    -- = ninja dash
    self.dash = false
    self.dash_turn_cnt = 0
end

function C_Ai:stanceTimeoutFormula()
    return 0.4 + math.random(0, 1) * math.random(1, 2)
end

function C_Ai:setWanderStance()
    self.stance = 'wander'
    self.stance_timer = 0
    self.stance_timeout = 0.5 + math.random(0, 1) * math.random(1, 4)
    self.jump_token = false
    if self.e_chase_flag then
        GAME:del_e(self.e_chase_flag)
        self.e_chase_flag = nil
    end
end

function C_Ai:setChaseStance()
    self.stance = 'chase'
    self.stance_timer = 0
    self.stance_timeout = self:stanceTimeoutFormula()
    self.jump_token = true
    -- = associate chase mark animation on top of enemy
    if S_Ai.debug_option.chase_flag and not self.e_chase_flag then
        self.e_chase_flag = E_FxEnemyChaseMark(self.e)
    end
end

-- --===========================#

S_Ai = Tiny.processingSystem()

S_Ai.filter = Tiny.requireAll('c_b', 'c_ai', 'c_pad')
S_Ai.active = false

-- S_Ai.e_chasers = {}
-- S_Ai.e_shooters = {}
-- S_Ai.e_punchers = {}
-- S_Ai.e_rocketers = {}
-- S_Ai.e_katanas = {}
-- S_Ai.e_bombers = {}

S_Ai.e_bomb_cnt = 0

function S_Ai:isFacingWall(e)
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

function S_Ai:isFacingEdge(e)
    local m =
        GAME.map
    local goal_x =
        e.c_b:mid_x()
    local x2 =
        goal_x + e.c_anim.dir * (e.c_b.w * .6)
    local y =
        e.c_b:bot() + 2

    local e_tl_1 = m:tile_at(goal_x, y)
    local e_tl_2 = m:tile_at(x2, y)

    if e_tl_1 then
        return e_tl_1.c_tile:isEdge(-e.c_anim.dir) and 
            (e_tl_2 == nil or e_tl_2.c_tile:has_prop(Tl.Prop.Empty))
    else
        return true
    end
end

function S_Ai:isFacingHero(e)
    local e_hero = GAME.e_hero
    local dir = e.c_anim.dir

    if dir == 1 then
        return e.c_b:mid_x() <= e_hero.c_b:mid_x()
    elseif dir == -1 then
        return e.c_b:mid_x() > e_hero.c_b:mid_x()
    end
end


function S_Ai:collectHeroInfo(e)
    local e_hero = GAME.e_hero
    local c_ai = e.c_ai

    local hero_ix, hero_iy = GAME.map:cooToIndex(e_hero.c_b:mid_x(), e_hero.c_b:mid_y())
    local enemy_ix, enemy_iy = GAME.map:cooToIndex(e.c_b:mid_x(), e.c_b:mid_y())

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
        math.abs(e.c_b:mid_x() - e_hero.c_b:mid_x())
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


-- function S_Ai:ninjaChase(e, dt)
--     local e_hero = GAME.e_hero
--     local c_ai = e.c_ai

--     local m = GAME.map

--     local hero_ix, hero_iy = m:cooToIndex(e_hero.c_b:mid_x(), e_hero.c_b:mid_y())
--     local enemy_ix, enemy_iy = m:cooToIndex(e.c_b:mid_x(), e.c_b:mid_y())

--     -- = turn towards hero
--     local is_hero_up = hero_iy < enemy_iy
--     local is_hero_down = hero_iy > enemy_iy
--     if c_ai.on_enter_tl then

--         if c_ai.is_hero_left and c_ai.dir == 1 then
--             c_ai.turn = true

--         elseif c_ai.is_hero_right and c_ai.dir == -1 then
--             c_ai.turn = true
--         end
--     end

--     -- = exit if conditions are not met
--     if not c_ai.on_enter_step or e.c_state_machine:is(St_NinjaJump) or e.c_state_machine:is(St_NinjaDash) then
--         return
--     end
--     -- = try to dash
--     if c_ai.on_enter_step and math.random(1, 100) < 10 then
--         c_ai.dash = true
--         return
--     end
--     -- = collect jump targets
--     local is_hero_aligned = hero_iy == enemy_iy

--     local jump_targets = {}
--     local jump_verts = {}

--     -- = get jump targets from navmap (jump up and down)
--     local nv_tl = GAME.navmap:tile_at(e.c_b:mid_x(), e.c_b:mid_y())
--     local nv_actions = {}

--     if is_hero_up or is_hero_aligned then
--         nv_actions = nv_tl.up
--     elseif is_hero_down then
--         nv_actions = nv_tl.down
--     end
--     -- = filter ladder actions
--     for _, action in ipairs(nv_actions) do
--         if action.dest then
--             local t = action.type
--             if t == NavAction.Type.Jump or t == NavAction.Type.Fall then
--                 table.insert(jump_verts, action.dest.tl)
--             end
--         end
--     end
--     -- = collect jump targets around ninja
--     local tl_1, tl_4, tl_5 = nil, nil, nil
--     if is_hero_aligned then

--         tl_1 = nil -- jump to hero
--         tl_4 = nil -- jump over hero
--         tl_5 = nil -- jump backwards

--         -- = jump to hero
--         tl_1 = m:getNextGroundTile(hero_ix - math.random(-2, 2), hero_iy)

--         if tl_1 then
--             table.insert(jump_targets, tl_1)
--         end
--         -- = jump over hero
--         if c_ai.is_hero_left then
--             local ix = hero_ix - (enemy_ix - hero_ix)
--             tl_4 = m:getNextGroundTile(ix, hero_iy)
--         elseif c_ai.is_hero_right then
--             local ix = hero_ix + (hero_ix - enemy_ix)
--             tl_4 = m:getNextGroundTile(ix, hero_iy)
--         end

--         if tl_4 then
--             table.insert(jump_targets, tl_4)
--         end
--         -- = jump backwards
--         if c_ai.is_facing_hero then
--             tl_5 = m:getNextGroundTile(enemy_ix - c_ai.dir * 2, hero_iy)
--         end

--         if tl_5 then
--             table.insert(jump_targets, tl_5)
--         end
--     end

--     -- = filter jump targets
--     local filtered = {}
--     local max_range = Tl.Dim * 6
--     for i, e_tl in ipairs(jump_targets) do
--         local filter = false
--         -- = don't jump onto hero
--         if e_tl.ix == enemy_ix and e_tl.iy == enemy_iy then
--             filter = true
--         end
--         -- = don't jump to far
--         if e_tl.c_b:dist_to(e.c_b) > max_range then
--             filter = true
--         end

--         if not filter then
--             table.insert(filtered, e_tl)
--         end
--     end
--     jump_targets = filtered
--     -- = pick a jump target at random 
--     -- = either from jump_targets or jump_verts
--     if math.random(1, 2) == 1 and #jump_targets > 0 then
--         local jump_tl = jump_targets[math.random(1, #jump_targets)]
       
--         -- = check if jump crosses WALL
--         if self:isValidJumpTile(e, jump_tl) then 
--             c_ai.jump_to = jump_tl
--            -- = no shuriken if getting close to hero
--             c_ai.jump_shuriken_enabled = jump_tl ~= tl_1 and jump_tl ~= tl_4
--         end

--     elseif #jump_verts > 0 then

--         local jump_vert = jump_verts[math.random(1, #jump_verts)]
--         -- = navmap targets are always valid
--         c_ai.jump_to = jump_vert

--         if c_ai.is_hero_down then
--             c_ai.jump_shuriken_enabled = false
--         else
--             c_ai.jump_shuriken_enabled = true
--         end
--     end
-- end

-- function S_Ai:onNinjaType(e, dt)
--     local c_ai = e.c_ai
--     local c_sm = e.c_state_machine
--     local c_state = c_sm:get()
--     local e_hero = GAME.e_hero

--     if c_sm:is(St_NinjaJump) then
--         local kinematic_jump = c_state.kinematic_jump
--         local SHURIKEN_RANGE_MIN = Tl.Dim * 2

--         if c_state.is_on_enter then
--             local is_range_ok = e.c_b:dist_to(e_hero.c_b) > SHURIKEN_RANGE_MIN

--             c_ai.jump_streak = c_ai.jump_streak + 1
--             if c_ai.jump_streak == 1 and c_ai.jump_shuriken_enabled then
--                 c_ai.shoot_shuriken = math.random(1, 1) == 1 and is_range_ok
--             else
--                 c_ai.shoot_shuriken = false
--             end
--         end

--         if c_state.is_on_update then
--             local jump_dy = kinematic_jump.dir_y

--             local is_valid_x = math.abs(e.c_b:mid() - c_state.goal_x) < 16
--             local is_valid_y = nil
--             local is_valid_goal_y = e.c_b:mid_y() < c_state.goal_y - 32

--             if jump_dy == -1 then
--                 is_valid_y = (is_valid_goal_y) and (c_ai.is_hero_down)
--             elseif jump_dy == 1 and c_state.from_y == c_state.goal_y then
--                 is_valid_y = (is_valid_goal_y) and (c_ai.is_hero_down) and (kinematic_jump:getProgressToZenith(c_state.timer) > 80)
--             end

--             if c_ai.shoot_shuriken and is_valid_x and is_valid_y then
--                 c_ai.shuriken = true
--                 c_ai.stance = 'shuriken'
--             end

--             if c_state.on_landing then
--                 c_ai.jump_streak = c_ai.jump_streak - 1
--                 e.c_anim.dir = c_ai.is_hero_right and 1 or -1
--                 c_ai.stance = 'wander'
--             end
--         end
--     end

--     if c_sm:is(St_NinjaDash) then

--         if c_state.is_on_enter then
--             c_ai.dash_turn_cnt = 0
--         end

--         self:onGroundState(e, dt)

--         if c_ai.stance == 'chase' then

--             if c_ai.on_enter_tl and math.random(1, 100) < 25 then
--                 if c_ai.is_hero_left then
--                     e.c_anim.dir = -1
--                 else
--                     e.c_anim.dir = 1
--                 end
--             end
--         end

--         if c_ai.turn then
--             c_ai.dash_turn_cnt = c_ai.dash_turn_cnt + 1
--             if c_ai.dash_turn_cnt > 2 then
--                 c_sm:set(St_EnGround(e))
--             end
--         end

--         if c_ai.on_enter_tl and math.random(1, 100) < 10 then
--             c_sm:set(St_EnGround(e))
--         end

--     end
-- end

function S_Ai:isValidJumpTile(e, e_tl)
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

-- function S_Ai:monkeyTryMelee(e)
--     local x, y = nil, e.c_b:mid_y()
--     local w, h = 10, 6

--     if e.c_anim.dir == -1 then
--         x = e.c_b:mid_x() - w
--     else
--         x = e.c_b:mid_x()
--     end
--     local _, len = GAME.bump_world:queryRect(x, y, w, h, function(item)
--         return Xtype.is(item, E_Hero)
--     end)
--     if len > 0 then
--         e.c_ai.claw = true
--     end
-- end

-- function S_Ai:monkeyTryGrabHero(e)
--     local x, y = nil, e.c_b:mid_y()
--     local w, h = 10, 6

--     if e.c_anim.dir == -1 then
--         x = e.c_b:mid_x() - w
--     else
--         x = e.c_b:mid_x()
--     end
--     local _, len = GAME.bump_world:queryRect(x, y, w, h, function(item)
--         return Xtype.is(item, E_Hero)
--     end)
--     return len > 0
-- end

-- function S_Ai:monkeyTryDestroyTile(e)
--     if e.c_b.is_on_ground or e.c_b.has_hit_ground then
--         return
--     end

--     local x, y = e.c_b:left(), e.c_b:top()
--     local w, h = e.c_b.w, e.c_b.h

--     local e_tiles, len = GAME.bump_world:queryRect(x, y, w, h, function(item)
--         return Xtype.is(item, E_Tile) and item.c_tile:has_prop(Tl.Prop.Wall)
--     end)
--     for i = 1, len do
--         local e_tile = e_tiles[i]
--         GAME.map:destroy_tile(e_tile.ix, e_tile.iy, -e.c_anim.dir)
--     end
-- end


-- function S_Ai:monkeyChase(e)
--     local m = GAME.map
--     local e_hero = GAME.e_hero
--     local c_ai = e.c_ai
--     -- = melee atk
--     self:monkeyTryMelee(e)
--     -- = turn towards hero
--     local hero_ix, hero_iy = m:cooToIndex(e_hero.c_b:mid_x(), e_hero.c_b:mid_y())
--     local _, enemy_iy = m:cooToIndex(e.c_b:mid_x(), e.c_b:mid_y())

--     if c_ai.on_enter_tl then
--         c_ai.turn = 
--             (c_ai.is_hero_left and c_ai.dir == 1) or
--             (c_ai.is_hero_right and c_ai.dir == -1)
--     end

--     -- if self:monkeyTryGrabHero(e) then
--     --     c_ai.grab_hero = true
--     -- end
--     -- = exit if conditions are not met
--     if not c_ai.on_enter_step then
--         return
--     end

--     if math.random(100) < 10 and not c_ai.is_hero_aligned then
--         c_ai:setIdleStance()
--         c_ai.dir = 0
--         return
--     end

--     -- = collect jump targets
--      local is_hero_up = hero_iy < enemy_iy
--      local is_hero_down = hero_iy > enemy_iy

--      local jump_targets = {}
--      local jump_verts = {}
 
--      -- = get jump targets from navmap (jump up and down)
--      local nv_tl = GAME.navmap:tile_at(e.c_b:mid_x(), e.c_b:mid_y())
--      local nv_actions = {}
 
--      if is_hero_up then
--          nv_actions = nv_tl.up
--      elseif is_hero_down then
--          nv_actions = nv_tl.down
--      end
--      -- = filter ladder actions
--      for _, action in ipairs(nv_actions) do
--         if action.dest then
--             local t = action.type
--             if t == NavAction.Type.Jump or t == NavAction.Type.Fall then
--                 table.insert(jump_verts, action.dest.tl)
--             end
--         end
--     end
--     -- = jump to hero
--     local tl_1 = m:getNextGroundTile(hero_ix, hero_iy)
--     if tl_1 then
--         local dist = tl_1.c_b:dist_to(e.c_b)
--         if dist > Tl.Dim * 2 then
--             table.insert(jump_targets, tl_1)
--         end
--     end
--      -- = pick a jump target at random 
--      -- = either from jump_targets or jump_verts
--     if math.random(1, 2) == 1 and #jump_targets > 0 then
--         local jump_tl = jump_targets[math.random(1, #jump_targets)]
--         c_ai.jump_to = jump_tl
--         GAME.cam:shake(0.2, 6)

--     elseif #jump_verts > 0 then
--          local jump_vert = jump_verts[math.random(1, #jump_verts)]
--          c_ai.jump_to = jump_vert
--     end
-- end


-- function S_Ai:onMonkeyType(e, dt)
--     local c_ai = e.c_ai
--     local c_sm = e.c_state_machine
--     local c_state = c_sm:get()
--     local e_hero = GAME.e_hero

--     if c_sm:is(St_Jump) then

--         if c_state.is_on_enter then

--         end

--         if c_state.is_on_update then

--             if not c_state.on_landing then
--                 self:monkeyTryDestroyTile(e)
--             end

--             if math.random(1) == 1 and self:monkeyTryGrabHero(e) then
--                 c_ai.grab_hero = true
--             else
--                 self:monkeyTryMelee(e)
--             end
--         end
--     end
-- end
























-- = Rewritten AI
S_Ai.e_chasers = {}

S_Ai.debug_option = {
    move = false,
    melee = true,
    jump = false,
    gun = true,
    rocket = true,
    bomb = false,
    chase_flag = true,
    break_guard = false,
    dodge = false, -- dodge
}

local KATANA_RANGE_MIN = Tl.Dim * .5
local KATANA_RANGE_MAX = Tl.Dim * 1



-- = give chase tokens to enemies
-- = enables them to jump & use ladders & fall from edges 
function S_Ai:giveChaseTokens(dt)
    local e_enemies = table.clone(GAME.e_enemies)
    local e_hero = GAME.e_hero
    -- = sort enemies by closest to hero first
    table.sort(e_enemies, function(a, b)
        local dist_a = a.c_b:dist_to(e_hero.c_b)
        local dist_b = b.c_b:dist_to(e_hero.c_b)
        return dist_a < dist_b
    end)

    -- = filter the n closest enemies
    local n_closest = GAME.level * 2--math.floor(2 + GAME.level_enemy_cnt / 4)
    local e_enemies = table.slice(e_enemies, 1, n_closest)
    e_enemies = table.filter(e_enemies, function(e)
        local dist_x = math.abs(e.c_b:mid_x() - e_hero.c_b:mid_x())
        local dist_y = math.abs(e.c_b:mid_y() - e_hero.c_b:mid_y())

        return dist_x < Tl.Dim * 7 and dist_y < Tl.Dim * 5
    end)
    -- = pick n different enemies at random to chase hero
    local n = GAME.level
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

        -- if c_ai.stance == 'fall_at' then
        --     if not e.c_state_machine:is(St_EnGround) then
        --         c_ai.stance = 'wander'
        --     end
        -- end

        -- if c_ai.stance == 'shuriken' then
        --     if not e.c_state_machine:is(St_Shuriken) then
        --         c_ai.stance = 'chase'
        --     end
        -- end

        -- if c_ai.stance == 'idle' then
        --     if c_ai.stance_timer > c_ai.stance_timeout then
        --         c_ai:setWanderStance()
        --     else
        --         c_ai.stance_timer = c_ai.stance_timer + dt
        --         return
        --     end
        -- end

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

function S_Ai:searchIslandEdge(e_tl, dir)
    while e_tl do
        if e_tl.c_tile:isSolid() then
            if dir == 1 then
                return e_tl.c_b:left()
            else
                return e_tl.c_b:right()
            end
        end
        if e_tl.c_tile:neighbor(0, 1).c_tile:isEdge(-dir) then
            if dir == 1 then
                return e_tl.c_b:right()
            else
                return e_tl.c_b:left()
            end
        end

        e_tl = e_tl.c_tile:neighbor(dir, 0)
    end
    return nil
end

function S_Ai:collectEnemiesOnHeroIsland()
    --= search stops when we find a tile that is a wall or corner
    local e_hero = GAME.e_hero
    local e_tl = GAME.map:tile_at(e_hero.c_b:mid_x(), e_hero.c_b:mid_y())

    if not e_tl then return {} end

    local x1 = self:searchIslandEdge(e_tl, -1)
    local x2 = self:searchIslandEdge(e_tl, 1)

    local y1 = e_tl.c_b:top()
    local y2 = e_tl.c_b:bot()

    if x1 and x2 and y1 and y2 then
        -- GAME:debugDrawRect(x1, e_tl.c_b:top(), x2 - x1, 32, nil, 0.1)
        GAME:debugDrawRect(x1, y1, x2 - x1, y2 - y1, nil, 0.1)
        local e_enemies = table.filter(GAME.e_enemies, function(e)
            local c_b = e.c_b
            return c_b:intersects(x1, y1, x2, y2) and c_b.is_on_ground
        end)
        return e_enemies
    end
    return {}
end

function S_Ai:preProcess(dt)
    self.e_enemies = {}
    self.e_enemies_on_island = self:collectEnemiesOnHeroIsland()
    -- if #self.e_enemies_on_island > 0 then
    --     print('enemies on island: ' .. #self.e_enemies_on_island)
    -- end
    if S_Ai.debug_option.jump then
        self:giveChaseTokens(dt)
    end
end

function S_Ai:process(e)
    -- = update chase mark pos (for debug purposes)
    if S_Ai.debug_option.chase_flag then
        local e_chase_flag = e.c_ai.e_chase_flag
        if e_chase_flag then
            e_chase_flag.c_b:set_mid_x(e.c_b:mid_x())
            e_chase_flag.c_b:set_mid_y(e.c_b:top() - 14)
        end
    end

    self:resetActions(e)
    self:collectMapInfo(e)
    self:collectHeroInfo(e)

    -- self.e_closest_enemies = {}
    -- for i, e_en in ipairs(self.e_enemies) do

    -- end

    local c_sm = e.c_state_machine

    if c_sm:is(St_EnGround) then
        self:execGroundActions(e)
    elseif c_sm:is(St_NinjaJump) then
        self:execJumpActions(e)
    elseif c_sm:is(St_Jump) then
        self:execJumpActions(e)
    elseif c_sm:is(St_Ladder) then
        self:execLadderActions(e)
    elseif c_sm:is(St_EnOnGuard1) then
        self:execGuardActions(e)
    end

    -- = flags set from somewhere else 
    -- = reset on exit allows flags to be "true" at least 1 frame
    e.c_ai.is_blocking_shooter = false
end

function S_Ai:resetActions(e)
    local c_ai = e.c_ai
    local c_state = e.c_state_machine:get()
    local c_prev_state = e.c_state_machine.prev_state

    c_ai.act_jump = false
    c_ai.act_punch = false
    c_ai.act_duck = false
    c_ai.act_turn = false
    c_ai.act_katana = false
    c_ai.act_bomb = false
    c_ai.act_shuriken = false

    if c_ai.act_jump_kick then
        e:off('c_jump_kick')
        c_ai.act_jump_kick = false
    end

    if Xtype.is(c_state, St_NinjaJump) and c_state.on_landing then
        -- local jump_chance = 50
        -- if math.random(1, 100) < jump_chance then
        -- end
        Timer.after(2, function()
            if e then e.c_ai.prevent_jump = false; end
        end)
        -- print('on_landing')
        -- print('state', c_state)
    end


    if not e:has_active('c_jump_kick') and not e.c_state_machine:is(St_NinjaJump) then
        e:on('c_jump_kick')
    end

    -- = reset dodge action
    if c_ai.act_dodge then
        if not e.c_state_machine:is(St_EnDuck) then
            c_ai.act_dodge = false
        end
    end
    -- = reset break guard action
    if c_ai.act_break_guard and not e.c_state_machine:is(St_EnOnGuard1) then
        c_ai.act_break_guard = false
        c_ai.break_guard_cooldown = 1
    end
    -- = reset ladder action
    if c_ai.act_ladder then
        if not e.c_state_machine:is(St_Ladder) then
            c_ai.act_ladder = nil
        end
    end
    -- = reset fall action
    if c_ai.act_fall then
        if not e.c_state_machine:is(St_EnGround) then
            c_ai.act_fall = false
        end
    end
    -- = reset gun action & prevent gun spamming
    if c_ai.act_gun or c_ai.act_gun_duck then
        if not e.c_state_machine:is(St_Gun) and not e.c_state_machine:is(St_GunDucked) then
            e:off('c_gun')
            c_ai.act_gun = false
            c_ai.act_gun_duck = false
            local time_to_wait = math.random() * 1.5
            Timer.after(time_to_wait, function()
                if e then
                    e:on('c_gun')
                end
            end)
        end
    end
    -- = reset rocket action & prevent rocket spamming
    if c_ai.act_rocket then
        if not e.c_state_machine:is(St_Rocket) then
            e:off('c_rocket')
            c_ai.act_rocket = false
            local time_to_wait = 2 + math.random() * 4
            Timer.after(time_to_wait, function()
                if e then
                    e:on('c_rocket')
                end
            end)
        end
    end
end

function S_Ai:collectMapInfo(e)
    local c_b = e.c_b
    local c_ai = e.c_ai
    local map = GAME.map

    c_ai.is_facing_wall = self:isFacingWall(e)
    c_ai.is_facing_edge = self:isFacingEdge(e)
    --=
    c_ai.cur_step =
        math.floor(e.c_b:mid_x() / c_ai.step_size)
    c_ai.on_enter_step =
        c_ai.old_step and c_ai.cur_step ~= c_ai.old_step
    c_ai.old_step = c_ai.cur_step
    --=
    c_ai.cur_tile =
        map:tile_at(e.c_b:mid())
    c_ai.bot_tile =
        map:tile_at(e.c_b:mid_x(), e.c_b:bot() + 2)
    c_ai.on_enter_tile = 
        c_ai.old_tile and c_ai.cur_tile ~= c_ai.old_tile
    -- = progress on current tile from 0 to 32/-32 (depending on dir)
    c_ai.cur_tile_progress = 0
    if c_ai.cur_tile then
        if e.c_anim.dir == 1 then
            c_ai.cur_tile_progress = e.c_b:mid_x() - c_ai.cur_tile.c_b:left()
        else
            c_ai.cur_tile_progress = c_ai.cur_tile.c_b:right() - e.c_b:mid_x()
        end
    end
    -- = 
    c_ai.nav_tile =
        GAME.navmap:tile_at(e.c_b:mid_x(), e.c_b:mid_y())

    if c_ai.nav_tile then
        c_ai.nav_act_up = c_ai.nav_tile.up
        c_ai.nav_act_down = c_ai.nav_tile.down
    end

    c_ai.is_hovering_ladder_down =  c_ai.bot_tile 
        and c_ai.bot_tile.c_tile:has_prop(Tl.Prop.Ladder)
    c_ai.is_hovering_ladder_up = c_ai.cur_tile 
        and c_ai.cur_tile.c_tile:has_prop(Tl.Prop.Ladder)

    -- = look upfront for enemies & bullets (for dodging & turning)
    local x, y, w, h = c_b:mid_x(), c_b:bot()-32, 32, 8
    if e.c_anim.dir == -1 then
        x = x - w
    end
    -- GAME:debugDrawRect(x, y, w, h, nil, 0.02)
    local cols, _ = GAME.bump_world:queryRect(x, y, w, h, function(item)
        if Xtype.is(item, E_Bullet) then
            return true
        elseif Xtype.is(item, E_Enemy) and item ~= e then
            return true
        end
    end)
    c_ai.upfront_collisions = cols
end

function S_Ai:evalTurnAction(e)
    local c_ai = e.c_ai

    if c_ai.act_fall then
        return
    end
    -- = force turn if facing wall
    if c_ai.is_facing_wall then
        c_ai.act_turn = true
        return
    end
    -- = force turn if facing edge and not falling
    if c_ai.is_facing_edge then
        c_ai.act_turn = true
        return
    end
    -- = turn if e obstructs shooter
    if e.c_ai.is_blocking_shooter then
        local e_shooter = e.c_ai.is_blocking_shooter
        if e_shooter.c_anim.dir == e.c_anim.dir and c_ai.on_enter_step then
            if math.random(1, 100) > 80 then
                c_ai.act_turn = true
            end
        end
    end
    -- = try turn if facing away from hero
    -- = collective behaviour ?
    if not c_ai.is_facing_hero and c_ai.on_enter_step then
        local turn_chance =  c_ai.stance == 'chase' and 50 or 90
        c_ai.act_turn = math.random(1, 100) > turn_chance
    end
    -- = try turn if too many upfront collision enemies
    -- = going towards same direction
    if not c_ai.act_turn then
        local allies_count = 0
        -- = count allies 
        for _, e_item in ipairs(c_ai.upfront_collisions) do
            if Xtype.is(e_item, E_Enemy) and e_item.c_state_machine:is(St_EnGround) then
                if e_item.c_anim.dir == e.c_anim.dir then
                    allies_count = allies_count + 1
                end
            end
        end
        -- = turn chance increases with allies count
        if c_ai.on_enter_step and allies_count > 1 and c_ai.stance == 'wander' then
            local turn_chance = allies_count * 10
            c_ai.act_turn = math.random(1, 100) <= turn_chance
        end
    end

    -- = if no jump action => try turn wether facing hero or not
    -- = TODO
end

-- = chase stance increases chance of falling
function S_Ai:evalFallAction(e)
    local c_ai = e.c_ai
    local fall_chance = c_ai.stance == 'chase' and 80 or 40
    
    if not e:has_active('c_fall_from_edge') then
        return
    end
    -- = prevent falling if hero not somewhere below
    if not c_ai.is_hero_down then
        return
    end
    -- = prevent spamming fall action chance
    if c_ai.act_fall then
        return
    end
    -- = try fall
    if e.c_ai.is_facing_edge then
        if math.random(1, 100) <= fall_chance then
            c_ai.act_fall = true
        end
    end
end

function S_Ai:evalJumpAction(e)
    local c_ai = e.c_ai
    local nav_actions = {}

    if c_ai.act_fall or c_ai.act_turn then
        return
    end

    if e.is_carrying_hero then
        return
    end
    -- = Prevent jump spamming
    if c_ai.prevent_jump then
        return
    else
        local jump_chance = 50
        if math.random(1, 100) < jump_chance then
            local prevent_time = 0.5 + math.random() * 0.5

            c_ai.prevent_jump = true
            Timer.after(prevent_time, function()
                if e then e.c_ai.prevent_jump = false end
            end)
            return
        end

    end
    -- = get jump targets above
    if c_ai.is_hero_up then
        nav_actions = c_ai.nav_tile.up
    end
    -- = get jump targets below
    if c_ai.is_hero_down then
        nav_actions = c_ai.nav_tile.down
    end
    -- = filter out fall & ladder actions
    nav_actions = table.filter(nav_actions, function(action)
        return action.type == "Jump"
    end)
    -- = pick one at pseudo-random
    local jump_action = nil

    if #nav_actions > 0 then
        -- = higher proba to jump to the first target from left to right
        -- = irand == 4 implies jumpin onto hero most of the time
        local irand = nil        
        local rand = math.random(1, 100)

        if rand < 50 then
            irand = 1
        elseif rand < 70 then
            irand = 2
        elseif rand < 80 then
            irand = 3
        elseif not GAME.e_hero.is_guarding and rand <= 100 then
            irand = 4
        end

        -- = pick action at random
        -- local irand = math.random(1, #nav_actions)

        if irand and irand <= #nav_actions then
            jump_action = nav_actions[irand]
        end
    end

    if jump_action then
        c_ai.act_jump = jump_action
    end
end

function S_Ai:isHeroMeleable(x1, y1, x2, y2)
    -- = check if hero intersects params
     return GAME.e_hero.c_b:intersects(x1, y1, x2, y2)
 end

function S_Ai:evalPunchAction(e)
    local c_ai = e.c_ai
    local c_anim = e.c_anim

    local x1 = e.c_b:mid_x() + c_anim.dir * 12
    local x2 = e.c_b:mid_x() + c_anim.dir * 14
    local y1 = e.c_b:bot() - 8
    local y2 = e.c_b:bot() + 16

    local x, y, w, h = math.segToRect(x1, y1, x2, y2)
    GAME:debugDrawRect(x, y, w, h, nil, 0.02)

    if
        self:isHeroMeleable(x1, y1, x2, y2)
        and not GAME.e_hero.c_state_machine:is(St_Ladder) 
        and not GAME.e_hero.c_state_machine:is(St_HangToPlatf) 
        and GAME.e_hero.is_punchable
    then
        c_ai.act_punch = true
    end
end

function S_Ai:evalKatanaAction(e)
    local c_ai = e.c_ai
    local c_anim = e.c_anim
    local x1 = e.c_b:mid_x() + c_anim.dir * KATANA_RANGE_MIN
    local x2 = e.c_b:mid_x() + c_anim.dir * KATANA_RANGE_MAX
    local y1 = e.c_b:bot() - 8
    local y2 = e.c_b:bot() + 16

    -- local x, y, w, h = math.segToRect(x1, y1, x2, y2)
    -- GAME:debugDrawRect(x, y, w, h, nil, 0.5)

    if self:isHeroMeleable(x1, y1, x2, y2) and self:isLineOfSightClear(e, false) then
        c_ai.act_katana = true
    end
end

function S_Ai:isHeroInRange(e, min_x, max_x, min_y, max_y)
    local dist_x = math.abs(e.c_b:dist_x(GAME.e_hero.c_b))
    local dist_y = math.abs(e.c_b:dist_y(GAME.e_hero.c_b))

    return dist_x >= min_x and dist_x <= max_x and dist_y >= min_y and dist_y <= max_y
end

function S_Ai:isHeroInGunRange(e)
    return self:isHeroInRange(e, GUN_RANGE_MIN, GUN_RANGE_MAX, 0, 6)
end

function S_Ai:isHeroInRocketRange(e)
    return self:isHeroInRange(e, ROCKET_RANGE_MIN, ROCKET_RANGE_MAX, 0, 6)
end

function S_Ai:isLineOfSightClear(e, enable_enemy_check, ally_safty_dist)
    local e_hero = GAME.e_hero

    ally_safty_dist = ally_safty_dist or 0

    local x1 = e.c_b:mid_x() - e.c_anim.dir * ally_safty_dist
    local x2 = e_hero.c_b:mid_x()
    local y1 = e.c_b:bot() - 32
    local y2 = e.c_b:bot() - 2

    local x, y, w, h = math.segToRect(x1, y1, x2, y2)
    GAME:debugDrawRect(x, y, w, h, nil, 0.2)

    local is_blocking_shooter = false
    local _, len = GAME.bump_world:queryRect(x, y, w, h, function(item)
        if Xtype.is(item, E_Tile) and item.c_tile:isSolid() then
            return true
        elseif enable_enemy_check and Xtype.is(item, E_Enemy) and item ~= e and not item.is_carried then -- and e.is_hittable then
            if 
                (e.c_anim.dir ==  1 and item.c_b:mid_x() < e.c_b:mid_x() and item.c_anim.dir ==  1) or
                (e.c_anim.dir == -1 and item.c_b:mid_x() > e.c_b:mid_x() and item.c_anim.dir == -1)
            then
                if is_blocking_shooter == false then
                    item.c_ai.is_blocking_shooter = e
                end
            end
            return true
        end
    end)

    return len == 0
end

function S_Ai:evalGunAction(e)
    local c_ai = e.c_ai
    local hero_c_sm = GAME.e_hero.c_state_machine
    local is_hero_on_ground = hero_c_sm:is(St_HeroGround)
        or hero_c_sm:is(St_ClimbCorner) 
        or hero_c_sm:is(St_ClimbPlatf)
        or hero_c_sm:is(St_Duck)
    
    local ally_safty_dist = ENEMY_WALK_SPEED / (GUN_IDLE_TIME + 0.1)

    if is_hero_on_ground and self:isHeroInGunRange(e) and self:isFacingHero(e) and self:isLineOfSightClear(e, true, ally_safty_dist) then
        local duck = math.random(1, 100) > 50
        if duck then
            c_ai.act_gun_duck = true
        else
            c_ai.act_gun = true
        end
    end
end

function S_Ai:evalRocketAction(e)
    local c_ai = e.c_ai
    local hero_c_sm = GAME.e_hero.c_state_machine
    local is_hero_on_ground = hero_c_sm:is(St_HeroGround)
        or hero_c_sm:is(St_ClimbCorner) 
        or hero_c_sm:is(St_ClimbPlatf)

    local ally_safty_dist = ENEMY_WALK_SPEED / (ROCKET_TOTAL_TIME + 0.1)

    if is_hero_on_ground and self:isHeroInRocketRange(e) and self:isFacingHero(e) and self:isLineOfSightClear(e, true, ally_safty_dist) then
        c_ai.act_rocket = true
    end
end

function S_Ai:evalDodgeBullet(e, e_bullet)
    local is_dist_traveled_ok = e_bullet.c_projectile.dist_x > Tl.Dim * 3
    return is_dist_traveled_ok
end

function S_Ai:evalDodgeEnemy(e, e_en)
    local c_ai = e.c_ai

    if not e_en.c_state_machine:is(St_EnIsHit) then
        return false
    end

    local is_coming_front = (e_en.c_b.vx < 0 and e.c_anim.dir == 1) or (e_en.c_b.vx > 0 and e.c_anim.dir == -1)
    local is_going_up = e_en.c_b.vy <= 0
    local is_range_ok = c_ai.hero_dist_x > Tl.Dim * 1
    local can_hit_ally = e_en.c_state_machine:get().can_hit_ally
    local is_vx_ok = math.abs(e_en.c_b.vx) > Tl.Dim * 5

    return  is_coming_front and is_going_up and is_range_ok and can_hit_ally and is_vx_ok
end

function S_Ai:evalDodgeAction(e)
    local c_ai = e.c_ai
    local dodge_item = nil

    for _, e_item in ipairs(c_ai.upfront_collisions) do

        if Xtype.is(e_item, E_Bullet) and self:evalDodgeBullet(e, e_item) then
            dodge_item = e_item        
        elseif Xtype.is(e_item, E_Enemy) and self:evalDodgeEnemy(e, e_item) then
            dodge_item = e_item
        end

        if dodge_item then
            break
        end
    end

    if dodge_item then
        local dodge_chance = nil

        if Xtype.is(dodge_item, E_Bullet) then
            dodge_chance = 30
        elseif Xtype.is(dodge_item, E_Enemy) then
            local dist_mutator = math.floor(c_ai.hero_dist_x / 16) * 5
            dodge_chance = -5 + dist_mutator
        end

        if math.random(1, 100) <= dodge_chance then
            c_ai.act_dodge = true
        end
    end
end

-- = On_Ground Actions
-- = also specifies priority of actions
function S_Ai:execGroundActions(e)
    local c_ai = e.c_ai
    local c_pad = e.c_pad
    local c_anim = e.c_anim
    local c_sm = e.c_state_machine

    self:evalFallAction(e)
    self:evalTurnAction(e)

    if e:has_active('c_punch') and S_Ai.debug_option.melee then
        self:evalPunchAction(e)
    end

    if e:has_active('c_gun') and S_Ai.debug_option.gun then -- and c_ai.gun_token then
        self:evalGunAction(e)
    end

    if e:has_active('c_rocket') and S_Ai.debug_option.rocket then -- and c_ai.gun_token then
        self:evalRocketAction(e)
    end

    if e:has_active('c_katana') and S_Ai.debug_option.melee then
        self:evalKatanaAction(e)
    end

    if e:has_active('c_bomb') and S_Ai.debug_option.bomb then
        self:evalBombAction(e)
    end

    if e:has_active('c_dodge') and S_Ai.debug_option.dodge then
        self:evalDodgeAction(e)
    end

    if c_ai.stance == 'chase' then
        self:evalChaseActions(e) -- jump & ladder
    end

    -- = actions and priorities
    local hdir = c_anim.dir

    if c_ai.act_turn then
        c_pad:press(hdir == 1 and "left" or "right")
    elseif c_ai.act_punch then
        c_pad:press("punch")
    elseif c_ai.act_katana then
        c_pad:press("katana")
    elseif c_ai.act_jump then
        local e_target_tl = nil
        
        if Xtype.is(c_ai.act_jump, NavAction) then
            e_target_tl = c_ai.act_jump.dest.tl
        else
            e_target_tl = c_ai.act_jump
        end
        
        if Xtype.is(e, E_Ninja) then
            c_sm:set(St_NinjaJump(e, e_target_tl))
        else
            c_sm:set(St_Jump(e, e_target_tl))
        end
    elseif c_ai.act_gun then
        c_pad:press("gun")
    elseif c_ai.act_gun_duck then
        c_pad:press("gun_duck")
    elseif c_ai.act_rocket then
        c_pad:press("rocket")
    elseif c_ai.act_bomb then
        c_pad:press("bomb")
    elseif c_ai.act_dodge then -- dodge bullet & enemy-thrown
        c_sm:set(St_EnDuck(e, 0.4))
    elseif c_ai.act_ladder == 1 then
        c_pad:press("down")
    elseif c_ai.act_ladder == -1 then
        c_pad:press("up")
    elseif S_Ai.debug_option.move then -- walk left & right
        c_pad:press(hdir == 1 and "right" or "left")
    end
end

function S_Ai:execJumpActions(e)
    local c_ai = e.c_ai
    local c_anim = e.c_anim
    local c_sm = e.c_state_machine

    -- = turn towards hero on landing
    if c_sm:get().on_landing then
        c_anim.dir = c_ai.is_hero_right and 1 or -1
    end
    
    -- = Ninja Jump
    if Xtype.is(e, E_Ninja) then
        self:execNinjaJumpAction(e)
    end
end

function S_Ai:evalChaseActions(e)
    local c_ai = e.c_ai

    local is_ladder_enabled = e:has_active('c_ladder')
        and not e.is_carrying_hero
        and c_ai.cur_tile
        and c_ai.cur_tile_progress > 10 and c_ai.cur_tile_progress < Tl.Dim - 10

    local is_ladder_up = is_ladder_enabled and c_ai.is_hovering_ladder_up
    local is_ladder_down = is_ladder_enabled and c_ai.is_hovering_ladder_down

    -- local is_fall_enabled = not e.is_carrying_hero

    -- = use ladder
    if is_ladder_enabled then
        -- print('ladder enabledl')
        if c_ai.is_hero_up and is_ladder_up then
            c_ai.act_ladder = -1
        elseif c_ai.is_hero_down and is_ladder_down then
            c_ai.act_ladder = 1
        end
    -- = or try to jump
    elseif Xtype.is(e, E_Ninja) then
        self:evalNinjaJumpAction(e)
    else
        self:evalJumpAction(e)
    end
end

function S_Ai:execLadderActions(e)
    local c_ai = e.c_ai
    local c_pad = e.c_pad
    local c_anim = e.c_anim
    local c_sm = e.c_state_machine
    local state = c_sm:get()

    -- = turn towards hero on landing
    if c_sm:get().on_landing then
        c_anim.dir = c_ai.is_hero_right and 1 or -1
    end

    -- = go up or down
    if c_ai.act_ladder == 1 then
        c_pad:press("down")
    elseif c_ai.act_ladder == -1 then
        c_pad:press("up")
    end
end

function S_Ai:evalBombAction(e)
    local c_ai = e.c_ai

    if c_ai.act_gun then
        return
    end

    -- = prevent bombing in front of ladders
    if c_ai.is_hovering_ladder_up or c_ai.is_hovering_ladder_down then
        return
    end

    -- = prevent bombing while hero is too close
    local dist_to_hero = e.c_b:dist_to(GAME.e_hero.c_b)

    if dist_to_hero < Tl.Dim * 3 then
        return
    end

    -- = prevent bomb spamming
    c_ai.bomb_cooldown = c_ai.bomb_cooldown - love.timer.getDelta()
    if c_ai.bomb_cooldown > 0 then
        return
    end

    -- = try to drop a bomb
    local rand = love.math.random(1, 100)
    local bomb_chance = c_ai.stance == 'chase' and 50 or 90
    if rand > bomb_chance then
        c_ai.act_bomb = true
        c_ai.bomb_cooldown = 1 + love.math.random() * 4
    else
        c_ai.bomb_cooldown = 1 + love.math.random() * 2
    end
end

function S_Ai:execGuardActions(e)
    local c_ai = e.c_ai

    if not S_Ai.debug_option.break_guard then
        return
    end

    if e.c_state_machine:get().is_on_enter or c_ai.break_guard_cooldown == nil then
        c_ai.break_guard_cooldown = 1
    end

    -- = break guard
    c_ai.break_guard_cooldown = c_ai.break_guard_cooldown - love.timer.getDelta()
    if c_ai.break_guard_cooldown <= 0 then
        c_ai.act_break_guard = true
    end

    if not c_ai.act_break_guard then
        return
    end

    -- = 
    if e:has_active('c_punch') then
        e.c_pad:press("punch")
    elseif e:has_active('c_katana') then
        e.c_pad:press("katana")
    end
end


function S_Ai:collectNinjaJumpTargets()
    local MIN_JUMP_DIST = Tl.Dim * 2
    local jump_targets = {}

    -- if c_ai.is_hero_aligned then
    local ix, iy = nil, hero_iy
    
    -- = jump at melee range
    if c_ai.is_hero_left then
        ix, _ = map:to_index(e_hero.c_b:mid_x() - KATANA_RANGE_MAX, _)
    else
        ix, _ = map:to_index(e_hero.c_b:mid_x() + KATANA_RANGE_MAX, _)
    end
    table.insert(jump_targets, map:getNextGroundTile(ix, iy))

    -- = jump to hero
    if math.abs(c_ai.hero_dist_x) >= MIN_JUMP_DIST then
        table.insert(jump_targets, map:getNextGroundTile(hero_ix, hero_iy))
    end
    local mutator = math.random(2, 3)
    -- = jump backwards
    table.insert(jump_targets, map:getNextGroundTile(enemy_ix - mutator, enemy_iy))
    -- = jump frontwards
    if c_ai.hero_dist_x + mutator * Tl.Dim >= MIN_JUMP_DIST then
        table.insert(jump_targets, map:getNextGroundTile(enemy_ix + mutator, enemy_iy))
    end
    -- end

    -- = filter nil jump targets
    jump_targets = table.filter(jump_targets, function(tl)
        return tl ~= nil
    end)
end


function S_Ai:evalNinjaJumpAction(e)
    local c_ai = e.c_ai
    local nav_actions = {}
    local map = GAME.map
    local e_hero = GAME.e_hero

    if c_ai.act_fall or c_ai.act_turn then
        return
    end

    if e.is_carrying_hero then
        return
    end
    -- = Prevent jump spamming
    if c_ai.prevent_jump then
        return
    else
        c_ai.prevent_jump = true
    end
    -- =
    local hero_ix, hero_iy = map:cooToIndex(
        e_hero.c_b:mid_x(), e_hero.c_b:mid_y()
    )
    local enemy_ix, enemy_iy = map:cooToIndex(
        e.c_b:mid_x(), e.c_b:mid_y()
    )
    -- = collect jump targets around ninja
    local jump_targets = {}
    local MIN_JUMP_DIST = Tl.Dim * 2.5
    local MAX_JUMP_DIST = Tl.Dim * 4

    local is_range_x_ok = function(target_x)
        local dist_x = math.abs(e.c_b:mid_x() - target_x)
        return dist_x >= MIN_JUMP_DIST and dist_x <= MAX_JUMP_DIST
    end

    -- if c_ai.is_hero_aligned then
    local ix, iy = nil, hero_iy
    -- = jump at melee range
    local target_x = nil

    if c_ai.is_hero_left then
        target_x = e_hero.c_b:mid_x() - KATANA_RANGE_MAX
    elseif c_ai.is_hero_right then  -- right
        target_x = e_hero.c_b:mid_x() + KATANA_RANGE_MAX
    end
    if target_x and is_range_x_ok(target_x) then
        ix, _ = map:to_index(target_x, _)
        table.insert(jump_targets, map:getNextGroundTile(ix, iy))
    end
    -- = jump to hero
    if is_range_x_ok(e_hero.c_b:mid_x()) then
        table.insert(jump_targets, map:getNextGroundTile(hero_ix, hero_iy))
    end

    local mutator = math.random(2, 3)
    -- = jump backwards
    table.insert(jump_targets, map:getNextGroundTile(enemy_ix - mutator, enemy_iy))
    -- = jump frontwards
    if c_ai.hero_dist_x + mutator * Tl.Dim >= MIN_JUMP_DIST then
        table.insert(jump_targets, map:getNextGroundTile(enemy_ix + mutator, enemy_iy))
    end
    -- end

    -- = filter nil jump targets
    jump_targets = table.filter(jump_targets, function(tl)
        return tl ~= nil
    end)

    if is_hero_aligned or c_ai.is_hero_up then
        nav_actions = c_ai.nav_tile.up
    end
    -- = filter out fall & ladder actions
    for _, action in ipairs(nav_actions) do
        if action.dest then
            local t = action.type
            if t == NavAction.Type.Jump then
                table.insert(jump_targets, action.dest.tl)
            end
        end
    end
    -- = pick a jump target at random
    local jump_target = nil
    if #jump_targets > 0 then
        jump_target = jump_targets[math.random(1, #jump_targets)]
    end
    -- = validate jump target if it does not cross a WALL
    if jump_target and self:isValidJumpTile(e, jump_target) then
        c_ai.act_jump = jump_target
    end
end

function S_Ai:evalShurikenAction(e)
    local SHURIKEN_RANGE_MIN = Tl.Dim * 2

    local c_state = e.c_state_machine:get()
    local e_hero = GAME.e_hero
    local c_ai = e.c_ai

    local kinematic_jump = c_state.kinematic_jump
    local jump_dy = kinematic_jump.dir_y
    local to_zenith = kinematic_jump:getProgressToZenith(c_state.timer)

    local is_valid_x = math.abs(e.c_b:mid() - c_state.goal_x) < 16
    local is_valid_y = nil
    local is_valid_goal_y = e.c_b:mid_y() < c_state.goal_y - 32
    local is_range_ok = e.c_b:dist_to(e_hero.c_b) > SHURIKEN_RANGE_MIN

    if jump_dy == -1 then
        is_valid_y = (is_valid_goal_y) and (c_ai.is_hero_down)
    elseif jump_dy == 1 and c_state.from_y == c_state.goal_y then
        is_valid_y = (is_valid_goal_y) and (c_ai.is_hero_down) and (to_zenith > 90)
    end

    if is_valid_x and is_valid_y and is_range_ok then
        c_ai.act_shuriken = true
    end

    if c_state.on_landing then
        c_ai.jump_streak = c_ai.jump_streak - 1
        e.c_anim.dir = c_ai.is_hero_right and 1 or -1
    end
end

function S_Ai:evalJumpKickAction(e)
    local c_ai = e.c_ai
    local e_hero = GAME.e_hero

    if e_hero.c_b.is_on_ground or not e_hero.is_hittable then
        return
    end

    if e_hero.c_state_machine:is(St_Ladder) then
        return
    end

    -- local x1 = e.c_b:mid_x() + c_anim.dir * 4
    -- local x2 = e.c_b:mid_x() + c_anim.dir * 18
    local x1 = e.c_b:mid_x() - 14
    local x2 = e.c_b:mid_x() + 14
    local y1 = e.c_b:bot() - 24
    local y2 = e.c_b:bot() - 8

    local x, y, w, h = math.segToRect(x1, y1, x2, y2)
    GAME:debugDrawRect(x, y, w, h, nil, 0.02)

    if self:isHeroMeleable(x1, y1, x2, y2) then
        c_ai.act_jump_kick = true
    end
end

function S_Ai:execNinjaJumpAction(e)
    local c_ai = e.c_ai
    local c_pad = e.c_pad
    local c_state = e.c_state_machine:get()

    if c_state.is_on_enter then
        c_ai.jump_streak = c_ai.jump_streak + 1

        if c_ai.jump_streak == 1 then--and c_ai.jump_shuriken_enabled then
            c_ai.try_shoot_shuriken = math.random(1, 1) == 1
        else
            c_ai.try_shoot_shuriken = false
        end
    end

    -- if c_state.on_landing then
    --     -- local jump_chance = 50
    --     -- if math.random(1, 100) < jump_chance then
    --     -- end
    --     Timer.after(2, function()
    --         if e then e.c_ai.prevent_jump = false; print('ok') end
    --     end)
    --     -- print('on_landing')
    --     -- print('state', c_state)
    -- end

    if e:has_active('c_shuriken') and c_ai.try_shoot_shuriken then
        self:evalShurikenAction(e)
    end

    if e:has_active('c_jump_kick') then
        self:evalJumpKickAction(e)
    end

    if c_ai.act_shuriken then
        c_pad:press('shuriken')
    elseif c_ai.act_jump_kick then
        c_pad:press('jump_kick')
    end
end



function evalNinjaJumpAction2()
    -- gather jump_up
    -- gather jump_down
    -- ladder_down
    -- ladder_up
    
end