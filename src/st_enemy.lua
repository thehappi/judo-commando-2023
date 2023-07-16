local KinematicJump = KinematicJump or require 'kinematic_jump'

--===========================#
--

St_EnGround = Class('St_EnGround', StateComp)

function St_EnGround:__construct(e)
    StateComp.__construct(self, e)
    --=
end

function St_EnGround:on_enter(e, c_b)
    e:off('c_gravity')
    e:on('c_move_hrz')
    e:on('c_anim_dir')

    e.is_grabbable=true
    e.is_catchable=false
    e.is_hittable=true
    e.is_pickable=false
    e.is_hittable_by_thrown = true
    c_b.is_platf_enabled = true

    e.c_b.vy = 0
    -- e.c_move_hrz:preset(Preset.C_Move_Hrz.St_EnGround)
    e.c_move_hrz.max = ENEMY_WALK_SPEED

    self.conc_ladder_st = e.c_state_machine:add_concurrential_state(St_Ladder(e, St_EnDuck, e.c_state_machine.ground_state, St_EnFall))
    e.c_b:set_w(10)
    e.c_b:set_h(Tl.Dim * 0.8)
end

function St_EnGround:on_update(e, c_b, c_pad)

    if not c_b.is_on_ground then
       return St_EnFall(e)
    end

    if c_pad:is_pressed('down') then
        return St_EnDuck(e)
    end

    if e.c_punch and c_pad:is_pressed('punch') then
        return St_Punch(e)
    end

    if e.c_gun then
        if c_pad:is_pressed('gun') then
            return St_Gun(e)
        
        elseif c_pad:is_pressed('gun_duck') then
            return St_GunDucked(e)
        end
    end

    if e.c_rocket and c_pad:is_pressed('rocket') then
        return St_Rocket(e)
    end

    if e.c_bomb and c_pad:is_pressed('bomb') then
        return St_DropBomb(e)
    end

    if e.c_katana and c_pad:is_pressed('katana') then
        return St_Katana(e)
    end

    if e.c_dash and c_pad:is_pressed('dash') then
        return St_NinjaDash(e)
    end

    if e.c_shuriken and c_pad:is_pressed('shuriken') then
        return St_Shuriken(e)
    end
end

function St_EnGround:on_exit(e)
    -- e.is_catchable = false
    e:off('c_move_hrz')
    e:off('c_gravity')
    e.c_state_machine:clear_concurrential_states()
    e.is_hittable_by_thrown = false
end

--===========================#
--

St_EnFall = Class('St_EnFall', StateComp)

function St_EnFall:__construct(e)
    StateComp.__construct(self, e)
    --=
end

function St_EnFall:on_enter(e)
    e:on('c_move_hrz', 'c_anim_dir', 'c_gravity')
    e.c_move_hrz:preset(Preset.C_Move_Hrz.St_Ground)
    self.conc_ladder_st = e.c_state_machine:add_concurrential_state(St_Ladder(e, St_EnDuck, e.c_state_machine.ground_state, St_EnFall))

end

function St_EnFall:on_update(e, c_b, c_pad)
    local colls = c_b.colls
    -- print('ici')
    if c_b.has_hit_ground or c_b.is_on_ground then
        -- return St_EnDuck(e, 0.07) -- que si max fall ?
        return e.c_state_machine.ground_state(e)
    end

    if e.c_claw and e.c_pad:is_pressed('claw') then
       return St_MkClaw(e)
    end
end

function St_EnFall:on_exit(e)
    e:off('c_move_hrz')
    e.c_state_machine:clear_concurrential_states()
end

--===========================#
--

St_EnDuck = Class('St_EnDuck', StateComp)

function St_EnDuck:__construct(e, timeout--[[ opt ]])
    StateComp.__construct(self, e)
    --=
    self.timeout = timeout
    self.timer = 0
end

function St_EnDuck:try_enter(e)
end

function St_EnDuck:on_enter(e)
    e:off('c_move_hrz')
    e:off('c_gravity')
    e.is_grabbable = true
    self.timer = 0
    e.c_b.vx = 0
    e.c_b.vy = 0
    self.prev_h = e.c_b.h
    e.c_b:set_h(10)
end

function St_EnDuck:on_update(e, c_b, c_pad)
    -- timed out state
    if self.timeout then
        self.timer = self.timer + love.timer.getDelta()
        if self.timer > self.timeout then 
            return e.c_state_machine.ground_state(e) 
        end
    end

    -- = stand back up
    if not self.timeout and not c_pad:is_pressed('down') then -- 
        return e.c_state_machine.ground_state(e)
    end

    -- = go through platf
    if c_pad:is_pressed_once('a') and c_b.is_on_platform then -- 
        return St_EnFall(e)
    end
end

function St_EnDuck:on_exit(e)
    e.c_b:set_h(self.prev_h)
end

--===========================#
--

St_EnOnGuard1 = Class('St_EnOnGuard1', StateComp)

function St_EnOnGuard1:__construct(e, e_hero)
    StateComp.__construct(self, e)
    --=
    self.e_hero = e_hero
end

function St_EnOnGuard1:on_enter(e, c_b)
    local h_dir = self.e_hero.c_anim.dir

    c_b.vx = 0
    c_b.vy = 0
    -- print('ici')
    e:off('c_move_hrz')
    e:off('c_gravity')

    e.is_hittable=true
end

function St_EnOnGuard1:on_update(e, c_b, c_pad)
    local e_hero_csm =self.e_hero.c_state_machine
    
    c_b.vx = 0
    e:off('c_move_hrz')

    if not e_hero_csm:is(St_OnGuard1) then
        if not e_hero_csm:is(St_OnGuard1Back) and not e_hero_csm:is(St_OnGuard1Up)and not e_hero_csm:is(St_OnGuard1Front) then
            return St_EnIsHit(e, self.e_hero.c_anim.dir*16, -128, false, false, false)
        end
    end

    if e:has_active('c_punch') and c_pad:is_pressed('punch') then
        return St_Punch(e, true)
    end

    if e:has_active('c_katana') and c_pad:is_pressed('katana') then
        return St_Katana(e, 0.01, true)
    end
end

--===========================#
--

St_EnIsHit = Class('St_EnIsHit', StateComp)

--[[
    @arg options = {

    }
]]
function St_EnIsHit:__construct(e, pow_x, pow_y, catchable, pickable, can_hit_ally--[[ =true ]], options)
    StateComp.__construct(self, e)
    --=
    self.pow_x = pow_x or 0
    self.pow_y = pow_y or 0

    self.st_combo = GAME.e_hero.c_state_machine:get()

    if options then
        self.is_clean_landing = options.is_clean_landing
    else
        self.is_clean_landing = false
    end

    if type(catchable) == "boolean" then
        e.is_catchable = catchable
    end

    if type(pickable) == "boolean" then
        e.is_pickable = pickable
    end

    self.has_hit_wall_or_ceil = false

    -- self.can_hit_ally = can_hit_ally == nil and true or can_hit_ally
    self.dist_x = 0
    self.dist_y = 0

    if can_hit_ally == nil then
        self.can_hit_ally = true
    else
        self.can_hit_ally = can_hit_ally
    end

    if self.can_hit_ally then
        self.can_hit_ally = false
        Timer.after(0.05, function() self.can_hit_ally = true end)
    end
    -- self.kinematic_jump = nil
    self.break_wall = true
end

function St_EnIsHit:on_enter(e, c_b)
    e:on('c_gravity')
    self.w = e.c_b.w
    self.h = e.c_b.h
    -- print(e.c_b.w)
    e.c_b:set_w(12)
    e.c_b:set_h(24)
    e.c_b:set_oy(.5)
    self.dist_travelled_x = 0
    self.dist_travelled_y = 0

    e.c_b.vx = self.pow_x
    e.c_b.vy = self.pow_y
    e.is_hittable = false
    e.is_hittable_by_thrown = false
    e.is_grabbable = false
    e.c_b.is_on_ground = false
    e.is_gunnable=true
    e.is_rocketable=true
    e.c_anim:set('gethit')
    self.start_x = e.c_b:mid_x()
    self.start_y = e.c_b:bot()
    -- query bump api for collision check
    -- check if e is colliding with a wall
    local _, len = GAME.bump_world:queryRect(c_b.x, c_b.y - 4, c_b.w, c_b.h, function(other)
        -- print(other, other.c_tile,other.c_tile:has_prop(Tl.Prop.Wall))
        return other ~= e and other.c_tile and other.c_tile:has_prop(Tl.Prop.Wall)
    end)
    if len > 0 then
        c_b.vy = 112
    end
    --= use kinematic equation to get highest tile reached
    --= initial velocity = pow_y
    --= final velocity = 0
    --= acceleration = gravity
    --= distance = ?

    -- local a = 50 * Tl.Dim
    -- local u = self.pow_y
    -- local v = 0
    -- local d = (v^2 - u^2) / (2*a)
    -- print('d', d)
end

function St_EnIsHit:applyOnHitShader(e)
    -- = on-hit shader effect
    e.c_anim.shader = SHADER_IS_HIT
    Timer.after(0.1, function() e.c_anim.shader = nil end)
end

function St_EnIsHit:onHitCeiling(e)
    self:applyOnHitShader(e)

    e.c_anim:set('hit_ceil'):set_origin(nil, -16)
    e.c_health:get_hit(3)
    e:on('c_gravity')
    e.c_b.vy = 0
    -- self.kinematic_jump = nil
end

function St_EnIsHit:getClosestHitAlly(e)
    local e_closest = nil
    local c_b = e.c_b
    for _, coll in ipairs(e.c_b.colls) do
        local e_oth = coll.other
        if
            Xtype.is(e_oth, E_Enemy) 
            and e_oth.is_hittable_by_thrown
            and c_b.vx ~= 0
            and math.distance(e_oth.c_b:mid_x(), e_oth.c_b:bot(), self.start_x, self.start_y) > 12
        then
            if e_closest == nil then
                e_closest  = e_oth
            else
                if c_b.vx > 0 and e_oth.c_b:left() < e_closest.c_b:left() then
                    e_closest = e_oth
                elseif c_b.vx < 0 and e_oth.c_b:right() > e_closest.c_b:right() then
                    e_closest = e_oth
                end
            end
        end
    end
    return e_closest
end

function St_EnIsHit:onHitAlly(e)
    local e_ally = self:getClosestHitAlly(e)
    local c_b = e.c_b

    if e_ally and not self.hit_ally then
        self.hit_ally = true

        e.c_anim_dir:off()
        e.c_anim.dir = -e.c_anim.dir

        local ix, iy =
            GAME.map:cooToIndex(c_b:mid_x(), c_b:bot())
        local e_ground_tl =
            GAME.map:getNextGroundTile(ix, iy)

        self.goal_x2 = e_ground_tl.c_b:mid_x()
        self.goal_y2 = e_ground_tl.c_b:bot()

        local G = Tl.Dim * 36
        local d = self.goal_y2 - c_b:bot()

        c_b.vx = c_b.vx * 0.25
        if c_b.vy > -96 and c_b.vy < 128 then
            c_b.vy = -96
        end
        -- = get distance from current position to goal position
        local dist_y = nil
        if c_b.vy < 0 then
            dist_y = math.kinematic_distance2(c_b.vy, 0, G)
            dist_y = math.abs(dist_y) * 2 + d
        else
            dist_y = d
        end
        -- = get time to reach goal position
        local t2 = math.kinematic_time(c_b.vy, G, dist_y)
        -- = get distance x in time t2
        local dist_x = math.kinematic_distance(c_b.vx, 0, t2)
        
        if math.abs(dist_x) > Tl.Dim * 2.5 then
            dist_x = Tl.Dim * 2.5
        end
        -- = get vx from dist_x and t2
        c_b.vx = math.abs(dist_x) / t2 * e.c_anim.dir
        --=
        e_ally.c_state_machine:set(
            St_EnIsHit(e_ally, -e.c_b.vx*.8, -154, false, true, false)
        )
        e_ally.c_anim_dir:off()
        e_ally.c_anim.dir = e.c_anim.dir
        -- print('dist_x', dist_x)

        self.can_hit_ally = false
        e.is_catchable = false
    end
end

function St_EnIsHit:onHitWall(e)
    -- self.has_hit_wall = true
end

function St_EnIsHit:getLandingTile(e)
    local a = 50 * Tl.Dim
    local u = e.c_b.vy
    local v = 0
    local d = (v^2 - u^2) / (2*a)

    local ix, iy = 
        GAME.map:cooToIndex(e.c_b:mid_x(), e.c_b:top() + d)

    return GAME.map:getNextGroundTile(ix, iy)
end

function St_EnIsHit:on_update(e, c_b, c_pad)
    local c_health = e.c_health
    local c_b = e.c_b
    local dt = love.timer.getDelta()

    self.dist_travelled_x = self.dist_travelled_x + math.abs(c_b.vx) * dt
    self.dist_travelled_y = self.dist_travelled_y + math.abs(c_b.vy) * dt

    self.dist_x = self.dist_x + (c_b:mid_x() - c_b.prev_x)
    self.dist_y = self.dist_y + (c_b:bot() - c_b.prev_y)

    -- = Hit ceiling
    if c_b.has_hit_ceil and not self.has_hit_ceil then
        -- print('en hit ceil st')
        self.has_hit_ceil = true
        self:onHitCeiling(e)
    end

    -- = Hit wall => setup kinematic bounce
    if c_b.has_hit_wall and not self.hit_wall then
        -- print('en hit wall st')
        local e_ground_tl = self:getLandingTile(e)

        if e_ground_tl then
            self.e_ground_tl = e_ground_tl
            self.goal_x = e_ground_tl.c_b:mid_x()
            self.goal_y = e_ground_tl.c_b:bot()
        else
            self.goal_x = c_b:mid_x() - 16 * e.c_anim.dir
            self.goal_y = c_b:bot() + 128
        end
        --= Try break wall
        local jewel_color = e.jewel_color
        local is_break_enabled = (jewel_color == 'green' or jewel_color == 'blue') and self.break_wall

        if is_break_enabled then
            local BREAK_CHANCE = 8

            local coll = c_b.has_hit_wall
            local e_tl = c_b.has_hit_wall.other
            local is_empty_below = e_tl and e_tl.c_tile:isEmptyBelow()
            local is_breaking = math.random(1, 100) <= BREAK_CHANCE

            if coll.normal.y == 0 and coll.normal.x ~= 0 and e_tl and not is_empty_below and is_breaking then
                GAME.map:destroy_tile(e_tl.ix, e_tl.iy, e.c_anim.dir)
                e.c_b:set_top(e_tl.c_b:top()+2, true)
                c_b.vy = 112
                c_b.has_hit_wall = false
                self.break_wall = false
                return
            end
        end
        self.hit_wall = true

        e.c_anim_dir:off()
        e.c_b.vx = 0

        -- = calculate time to reach ground
        local G = Tl.Dim * 36
        local d = self.goal_y - c_b:bot()
        -- print( 'ici', self.dist_travelled_x)
        if Xtype.is(self.st_combo, St_OnGuard2Combo) and self.dist_travelled_x < 16 and self.dist_travelled_y < 16 then
            c_b.vy = -174
        end

        self.t = math.kinematic_time(c_b.vy, G, d)
        -- print(self.t, c_b.vy, G, d)
        self.timer = 0
        self:applyOnHitShader(e)
        e.c_anim:set('hit_wall'):set_origin(3, nil)
        e.c_health:get_hit(3)
    end

    if self.hit_wall then
        self.timer = self.timer + love.timer.getDelta()
        if not self.has_bounced and (self.timer > 0.175 or self.timer > self.t) then
            self.has_bounced = true

            local dist_x = -e.c_anim.dir * math.abs(c_b:mid_x() - self.goal_x)
            c_b.vx = (dist_x / self.t)
            -- = if self.t is too small, prevent huge vx
            if math.abs(c_b.vx) > 500 then
                -- print ('vx', c_b.vx)
                c_b.vx = 0
            end

            if self.t >= 0.175 then
                e.c_anim:set('gethit')
            end
        end
    end
    -- = Hit ally
    if self.can_hit_ally then
        self:onHitAlly(e)
    end
    -- = Hit ground
    if e.c_b.is_on_ground then
        -- print ('en hit ground st')
        if self.hit_wall then
            c_b:set_mid_x(self.goal_x)
        end

        if self.e_ground_tl then
            e.c_b:set_bot(self.e_ground_tl.c_b:bot(), false)
        end

        if (self.is_clean_landing) then
            return St_EnDuck(e, 0.3)
        else
            return St_EnHitGround(e)
        end
    end

end

function St_EnIsHit:on_exit(e, c_b, c_pad)
    e.is_catchable=false
    e.is_pickable=false
    e.is_gunnable=false
    e.c_b:set_w(self.w)
    e.c_b:set_h(self.h)
    e.c_b:set_oy(1)
    e.c_b.vy = 0
    e.c_b.vx = 0
    e.c_anim_dir:on()
    e.c_anim.shader = nil
end

--===========================#
--

St_EnHitGround = Class('St_EnHitGround', StateComp)

function St_EnHitGround:__construct(e)
    StateComp.__construct(self, e)
    --=
end

function St_EnHitGround:on_enter(e, c_b)
    e.c_anim:set('hit_ground'):set_origin(nil, -6)

    

    e.c_b.vx=0
    e.c_b.vy=0

    e.is_hittable=false
    e.is_grabbable = false
    e.is_pickable=true
    e.is_armlockable=true

    e.c_gravity:off()
end

function St_EnHitGround:on_update(e, c_b, c_pad)
    if e.c_health.hp == 0 then
        return St_EnDead(e)
    end

    if e.c_anim:get_frame() == 2 and not self.trigger then
        self.trigger = true
        self.w = c_b.w
        self.h = c_b.h
        c_b:set_w(24)
        c_b:set_h(8)
    end

    if e.c_anim.cur_key == 'hit_ground' and  e.c_anim.is_over then
        
        e.c_anim:set('getup')
        -- c_b:set_w(self.w)
        e.is_armlockable = false
        e.is_pickable = false
        e.is_grabbable = true

    elseif e.c_anim.cur_key == 'getup' and e.c_anim.is_over then
        return e.c_state_machine.ground_state(e)
    end
end

function St_EnHitGround:on_exit(e, c_b, c_pad)
    -- if self.old_w then
    --     e.c_b:set_w(self.old_w)        
    -- end
    e.is_pickable = false
    e.is_armlockable = false
    c_b:set_w(self.w)
    c_b:set_h(self.h)
    
    -- e.is_catchable=true
    -- e:on('c_gravity')
    -- e.c_b.vy=0
    -- c_b:set_w(self.w)

end

--===========================#
--

St_EnDead = Class('St_EnDead', StateComp)

function St_EnDead:__construct(e)
    StateComp.__construct(self, e)
    --=
    self.timer = 0
    self.clear_at=0.75
    --=
end

function St_EnDead:on_enter(e, c_b)
    e.c_move_hrz:off()
    self.w = c_b.w
    self.h = c_b.h
    c_b:set_w(24)
    c_b:set_h(8)
end

function St_EnDead:on_update(e, c_b)
    self.timer = self.timer + love.timer.getDelta()
    
    if self.timer > self.clear_at and not e.c_anim.blink_visible then
        e.c_anim:off()
        e.clear = true
    end
end

--===========================#
--

St_EnOnGuard2 = Class('St_EnOnGuard2', StateComp)

function St_EnOnGuard2:__construct(e, e_hero)
    StateComp.__construct(self, e)
    --=
    self.e_hero = e_hero
end


function St_EnOnGuard2:on_enter(e, c_b)
    e.c_anim:off()
    e.c_gravity:off()
    e.c_b.vy=0
    e.is_carried = true
    e.is_hittable = false
end

function St_EnOnGuard2:on_update(e, c_b, c_pad)
    local e_hero_csm = self.e_hero.c_state_machine

    e.c_b:set_mid_x(self.e_hero.c_b:mid_x())
    e.c_b:set_bot(self.e_hero.c_b:bot()-6)
    e.c_anim.dir = -self.e_hero.c_anim.dir
    
    if not e_hero_csm:is(St_OnGuard2) and not e_hero_csm:is(St_OnGuard2Combo) then
        return St_EnIsHit(e, self.e_hero.c_anim.dir*16, -70, false, false)
    end

    if not e:has_active('c_anim') and self.e_hero.c_anim.cur_key == 'combo2_enter' and self.e_hero.c_anim.frame_i == 4 then
        e.c_anim:on():set('onguard2')
    end
end

function St_EnOnGuard2:on_exit(e, c_b)
    e:on('c_anim')
    e.is_carried = false
end


--===========================#
--

St_EnOnGuard3 = Class('St_EnOnGuard3', StateComp)

function St_EnOnGuard3:__construct(e, e_hero)
    StateComp.__construct(self, e)
    --=
    self.e_hero = e_hero
end

function St_EnOnGuard3:on_enter(e, c_b)
    e.c_anim:off()
    e.c_gravity:off()
    e.c_b.vy=0
    e.c_b:set_bot(self.e_hero.c_b:bot()-2)
    e.is_carried = true
end

function St_EnOnGuard3:on_update(e, c_b, c_pad)
    local e_hero_csm = self.e_hero.c_state_machine
    local e_hero_cb = self.e_hero.c_b
    local e_hero_canim = self.e_hero.c_anim

    if not e_hero_csm:is(St_OnGuard3) and not e_hero_csm:is(St_OnGuard3Kick) and not e_hero_csm:is(St_OnGuard3Down) and not e_hero_csm:is(St_OnGuard3Up ) then
        e.is_pickable=false
        return St_EnIsHit(e, e_hero_canim.dir*16, -128)
    end
    if not e:has_active('c_anim') and e_hero_canim.cur_key == 'combo3_enter' and self.e_hero.c_anim.frame_i == 3 then
        e.c_anim:on():set('combo3_idle')
    end

    e.c_anim.dir = -e_hero_canim.dir
    e.c_b:set_mid_x(e_hero_cb:mid_x() - e.c_anim.dir * 4)

    if e_hero_csm:is(St_OnGuard3Kick) then

    elseif e_hero_csm:is(St_OnGuard3Down) then

    elseif e_hero_csm:is(St_OnGuard3Up) then

    end
end

function St_EnOnGuard3:on_exit(e, c_b)
    e:on('c_anim')
    e.is_carried = false
end


--===========================#
--

St_Punch = Class('St_Punch', StateComp)

function St_Punch:__construct(e, skip_charge)
    StateComp.__construct(self, e)
    --=
    self.skip_charge = skip_charge
end

function St_Punch:on_enter(e, c_b)
    e.is_catchable = true
    e.is_hittable = true
    e.c_move_hrz:off()
    e.c_b.vx = 0
    e.is_hittable_by_thrown = true
end

function St_Punch:on_update(e, c_b, c_pad)
    e.is_hittable = true

    if e.c_anim.is_over then
        return e.c_state_machine.ground_state(e)
    end

    if e.c_anim.frame_i == 2 and not self.trigger then
        self.trigger = true

        local e_hero = GAME.e_hero
        local dir=e.c_anim.dir
        local x = c_b:mid_x() + dir * 12
        local w = 8
        local y = c_b:bot() - 24
        local h = 8

        if dir == -1 then
            x = x - w
        end

        GAME:debugDrawRect(x, y, w, h, nil, 1)

        local _, len = GAME.bump_world:queryRect(x, y, w, h, function(e_item)
            if (Xtype.is(e_item, E_Hero)) then
                -- print('punching hero', e_item.is_punchable)
            end
            if Xtype.is(e_item, E_Hero) and e_item.is_punchable then
                -- if (e_item.c_b.vx < 0 and e.c_anim.dir == -1) then -- peut-etre que c'est trop facile de pouvoir se proteger comme ca
                --     return false
                -- elseif (e_item.c_b.vx > 0 and e.c_anim.dir == 1) then
                --     return false
                -- else
                    return true
                -- end
            else
                return false
            end
        end)

        if len > 0 then
            local pow_x, pow_y = dir * 160, -92
            e_hero.c_health:get_hit(2)
            e_hero.c_state_machine:force_set(St_HeroIsHit(e_hero, pow_x, pow_y))

            GAME:emit_blood(e_hero.c_b:mid_x(), e_hero.c_b:mid_y(), -e.c_anim.dir)

            c_b.vx=0
        end
    end
end

function St_Punch:on_exit(e, c_b)
    e.is_hittable = false
end


--===========================#
--

St_DropBomb = Class('St_DropBomb', StateComp)

function St_DropBomb:__construct(e)
    StateComp.__construct(self, e)
    --=
    self.ttl_drop_mine=0.4
    self.ttl_exit=self.ttl_drop_mine+0.2
    self.timer = 0
end

function St_DropBomb:on_enter(e, c_b)
    e.c_anim:set('mine')
end

function St_DropBomb:on_update(e, c_b, c_pad)
    local dir = e.c_anim.dir
    local spawn = V2(c_b:mid_x(), c_b:bot())

    self.timer = self.timer + love.timer.getDelta()

    if e.c_anim.is_over and self.timer > self.ttl_drop_mine and not self.trigger then
        GAME:add_e(E_Mine(spawn.x, spawn.y))
        self.trigger = true
    end

    if e.c_anim.is_over and self.timer > self.ttl_exit then
        return (St_EnGround(e))
    end
end


--===========================#
--

St_Rocket = Class('St_Rocket', StateComp)

function St_Rocket:__construct(e)
    StateComp.__construct(self, e)
    --=
    self.fx_aiming = nil
    self.step = nil
    self.timer = 0
end

function St_Rocket:on_enter(e, c_b)
    e.c_anim:set('rocket')
    e.is_hittable_by_thrown = true
    e.is_hittable = true
    self.step = nil
    self.timer = 0
    self.t_aiming_at = ROCKET_AIMING_AT
    self.t_idled = ROCKET_IDLE_TIME
end

function St_Rocket:on_update(e, c_b, c_pad)
    local dir = e.c_anim.dir
    local spawn = V2(c_b:mid_x()+dir*14, c_b:bot()-12)

    self.timer = self.timer + love.timer.getDelta()

    if not self.step and self.timer > self.t_aiming_at then
        self.fx_aiming = E_FxRocketAiming(spawn.x, spawn.y, dir)
        self.step = 'aiming'
    end

    if self.step == 'aiming' and self.fx_aiming.c_anim.is_over then
        GAME:del_e(self.fx_aiming)
        self.timer = 0
        self.step = 'hold_fire'
    end

    if self.step == 'hold_fire' then
        GAME:add_e(E_Rocket(spawn.x, spawn.y, dir, e))
        self.timer = 0
        self.step = 'idled'
    end

    if self.step == 'idled' and self.timer > self.t_idled then
        return e.c_state_machine.ground_state(e)
    end
end

function St_Rocket:on_exit(e, c_b)
    GAME:del_e(self.fx_aiming)
end

--===========================#
--

St_Gun = Class('St_Gun', StateComp)

function St_Gun:__construct(e )
    StateComp.__construct(self, e)
    --=
    self.ttl_idle=GUN_IDLE_TIME
    self.timer = 0
end

function St_Gun:on_enter(e, c_b)
    e.c_anim:set('gun')
    e.is_hittable = true
    e.is_hittable_by_thrown = true
    e.is_catchable = true
end

function St_Gun:on_update(e, c_b, c_pad)
    local dir = e.c_anim.dir
    local bullet_pos = V2(c_b:mid_x()+dir*12, c_b:bot()-26)

    if e.c_anim.is_over and not self.trigger then
        GAME:add_e(E_Bullet(bullet_pos.x, bullet_pos.y, dir, e))
        self.trigger = true
    end

    if self.trigger then
        self.timer = self.timer + love.timer.getDelta()
        if self.timer > self.ttl_idle then
            return e.c_state_machine.ground_state(e)
        end
    end
end

function St_Gun:on_exit(e, c_b)
    -- e.is_hittable = false
    e.is_catchable = false
end

--===========================#
--

St_GunDucked = Class('St_GunDucked', StateComp)

function St_GunDucked:__construct(e)
    StateComp.__construct(self, e)
    --=
    self.ttl_idle=GUN_IDLE_TIME
    self.timer = 0
    self.is_ducking = is_ducking or false
end

function St_GunDucked:on_enter(e, c_b)
    e.c_anim:set('gun_duck')
    e.is_hittable = true
    e.is_hittable_by_thrown = true
    e.is_catchable = true
    self.prev_h = e.c_b.h
    e.c_b:set_h(16)
end

function St_GunDucked:on_update(e, c_b, c_pad)
    local dir = e.c_anim.dir
    local bullet_pos = V2(c_b:mid_x()+e.c_anim.dir*12, c_b:bot()-16)

    if e.c_anim.is_over and not self.trigger then
        GAME:add_e(E_Bullet(bullet_pos.x, bullet_pos.y, dir, e))
        self.trigger = true
    end

    if self.trigger then
        self.timer = self.timer + love.timer.getDelta()
        if self.timer > self.ttl_idle then
            return e.c_state_machine.ground_state(e)
        end
    end
end

function St_GunDucked:on_exit(e, c_b)
    e.c_b:set_h(self.prev_h)
    -- e.is_hittable = false
    e.is_catchable = false
end


--===========================#
--

St_Katana = Class('St_Katana', StateComp)

function St_Katana:__construct(e, ttl_load, enable_trail_fx)
    StateComp.__construct(self, e)
    --=
    self.ttl_load=ttl_load or 0.2
    -- self.ttl_atk=0.15
    self.timer = 0
    
    if enable_trail_fx == nil then
        self.enable_trail_fx = true
    else
        self.enable_trail_fx = enable_trail_fx
    end
end

function St_Katana:on_enter(e, c_b)
    e.c_anim:set('katana')
    e.is_catchable = true
    e.is_hittable = true
    e.is_hittable_by_thrown = true
end

function St_Katana:on_update(e, c_b, c_pad)
    local c_anim = e.c_anim

    if c_anim.frame_i == 3 then
        c_anim:pause()
    end

    if c_anim.is_paused then
        self.timer = self.timer + love.timer.getDelta()
        if self.timer > self.ttl_load then
            c_anim:play()
            self.timer = 0
        end
    end

    if c_anim.is_over then
        self.timer = self.timer + love.timer.getDelta()
        if (self.timer > 0.1) then
           return e.c_state_machine.ground_state(e)
        end
    end

    if c_anim.frame_i > 4 and not self.fx_trg then
        if (self.enable_trail_fx) then
            
            self.katana_trail = GAME:add_e(
                E_FxKatanaTrail(0, c_b:bot()-24, c_anim.dir)
            )
            if c_anim.dir == 1 then
                self.katana_trail.c_b:set_right(c_b:mid_x()+Tl.Dim*1.5)
            else
                self.katana_trail.c_b:set_left(c_b:mid_x()-Tl.Dim*1.5)
            end

        end
        self.fx_trg = true
    end

    if c_anim.frame_i > 2 and c_anim.frame_i < 6 and c_anim.enter_frame then
        if not self.trigger and self.katana_trail then

            local dir=c_anim.dir
            local x = self.katana_trail.c_b:left()
            local w = self.katana_trail.c_b.w
            local y = self.katana_trail.c_b:top() 
            local h = self.katana_trail.c_b.h-4

            local _, len = GAME.bump_world:queryRect(x, y, w, h, function(e) 
                return Xtype.is(e, E_Hero) and e.is_hittable
            end)

            if len > 0 then
                local pow_x = dir * Tl.Dim * 6
                local pow_y = -100

                GAME.e_hero.c_state_machine:set(
                    St_HeroIsHit(GAME.e_hero, pow_x, pow_y)
                )
                GAME.e_hero.c_health:get_hit(3)
                self.trigger = true
            end
        end
    end

end

function St_Katana:on_exit(e, c_b)
    -- e.is_hittable = false
    e.is_catchable = false
end

--===========================#
--

St_Shuriken = Class('St_Shuriken', StateComp)

function St_Shuriken:__construct(e, jump_dir_x, jump_dir_y)
    StateComp.__construct(self, e)
    --=
    self.shoot_dir_x = GAME.e_hero.c_b:mid_x() >= e.c_b:mid_x() and 1 or -1
    self.shoot_dir_y = GAME.e_hero.c_b:mid_y() >= e.c_b:mid_y() and 1 or -1

    self.jump_dir_x = jump_dir_x
    self.jump_dir_y = jump_dir_y
end

function St_Shuriken:on_enter(e, c_b)
    e.c_gravity:off()
    e.c_anim:set('shuriken')
    e.c_anim.dir = self.shoot_dir_x
end

function St_Shuriken:on_update(e, c_b, c_pad)
    if e.c_anim.frame_i == 1 and e.c_anim.enter_frame then
        local anim_dir = e.c_anim.dir
        local spawn_at = V2(c_b:mid_x()+anim_dir*16, c_b:bot()-26)

        local e_shuriken = E_Shuriken(spawn_at.x, spawn_at.y, 0, 0, e)

        local adj = math.abs(e_shuriken.c_b:mid_x() - GAME.e_hero.c_b:mid_x())
        local opp = e_shuriken.c_b:mid_y() - GAME.e_hero.c_b:mid_y()
        local angle = math.atan2(opp, adj)

        e_shuriken.c_projectile.dir_x = math.cos(angle) * anim_dir
        e_shuriken.c_projectile.dir_y = -math.sin(angle)

        GAME:add_e(e_shuriken)
    end

    if e.c_anim.is_over then
        e.c_b.is_platf_enabled = self.jump_dir_y == -1  
        return St_EnFall(e)
    end
end

function St_Shuriken:on_exit(e, c_b)
    e.c_gravity:on()
    -- e.c_b.is_static = false
end

--===========================#
--

St_EnMeteorCombo = Class('St_EnMeteorCombo', StateComp)

function St_EnMeteorCombo:__construct(e, e_hero)
    StateComp.__construct(self, e)
    --=
    self.e_hero = e_hero
end

function St_EnMeteorCombo:on_enter(e, c_b)
    e.c_anim:set('combo_meteor')
    e.c_b:set_static()
end

function St_EnMeteorCombo:on_update(e, c_b, c_pad)
end

function St_EnMeteorCombo:on_exit(e, c_b, c_pad)
    e.c_b:set_dynamic()
end

--===========================#
--

St_NinjaDash = Class('St_NinjaDash', StateComp)

function St_NinjaDash:__construct(e, e_hero)
    StateComp.__construct(self, e)
    --=
    self.e_hero = e_hero
end

function St_NinjaDash:on_enter(e, c_b)
    e.c_move_hrz:on():preset(Preset.C_Move_Hrz.St_NinjaDash)
    -- e.c_gravity:on()
    e.c_anim_dir:on()
    e.c_anim:set('ninja_dash')
    e.is_grabbable = false
end

function St_NinjaDash:on_update(e, c_b, c_pad)

    -- = anim
    if c_b.vx > 0 or c_b.vx < 0 then
        e.c_anim:play()
    else
        e.c_anim:pause()
    end
end

function St_NinjaDash:on_exit(e, c_b, c_pad)
    e.c_move_hrz:off()
end

--===========================#
--

St_Jump = Class('St_Jump', StateComp)

function St_Jump:__construct(e, e_tl)
    StateComp.__construct(self, e)
    --=
    self.goal_x = GAME.map.x + (e_tl.ix-0.5) * Tl.Dim
    self.goal_y = GAME.map.y + (e_tl.iy) * Tl.Dim
    --=
    self.dist_x = self.goal_x - e.c_b:mid_x()
    self.dist_y = self.goal_y - e.c_b:bot()
    --=
    self.dir_x = self.dist_x < 0 and -1 or 1
    self.dir_y = self.dist_y < 0 and -1 or 1
end

function St_Jump:on_enter(e)
    e.c_move_hrz:off()
    e.c_gravity:off()
    e.is_grabbable=false
    e.is_catchable=false

    e.c_b.filter = function(e, oth)
        return nil
    end

    -- kinematic equation : jump time
    self.timer = 0
    self.v = 0 -- v is the initial velocity so it's 0 because we start from ground
    self.a = 55 * Tl.Dim -- a is the acceleration
    self.t = nil -- unknown
    self.u = nil -- unknown

    if self.dir_y > 0 then
        self.s = -2 * Tl.Dim
    else
        self.s = self.dist_y - 1.5 * Tl.Dim
    end
    self.u = -math.sqrt(self.v^2 - 2*self.a*self.s)
    self.t_top = -(self.u - self.v) / self.a
    
    local a = 0.5 * self.a
    local b = self.u
    local c = e.c_b:bot() - self.goal_y

    self.t = (-b + math.sqrt(b^2 - 4*a*c)) / (2*a)
end

function St_Jump:on_update(e, c_b)
    local dt = love.timer.getDelta()
    self.timer = self.timer + dt

    c_b.vy = self.u + self.a * self.timer
    c_b.vx = self.dist_x / self.t
    
    if self.on_landing then
        return St_EnDuck(e, 0.2)
    end

    if self.timer >= self.t then
        c_b.vx = 0
        c_b.vy = 0
        c_b:set_bot(self.goal_y)
        self.on_landing = true
        -- print('landing')
    end

    if e.c_claw and e.c_pad:is_pressed('claw') then
        return St_MkClaw(e) 
    end

    if e.c_grab_hero and e.c_pad:is_pressed('grab_hero') then
        return St_MkGrabHero(e) 
    end
end

function St_Jump:on_exit(e)
    e.c_b.filter=nil
    e.c_move_hrz:on()
    e.c_gravity:on()
    e.is_grabbable = true
    e.is_catchable = true
end

--===========================#


St_NinjaJump = Class('St_NinjaJump', StateComp)

function St_NinjaJump:__construct(e, e_tl, max_y)
    StateComp.__construct(self, e)
    --=
    self.from_x = e.c_b:mid_x()
    self.from_y = e.c_b:bot()
    --=
    self.goal_x = e_tl.c_b:mid_x()
    self.goal_y = e_tl.c_b:bot()
    --=
    self.from_ix, self.from_iy = GAME.map:cooToIndex(self.from_x, self.from_y)
    --=
    self.goal_ix = e_tl.ix
    self.goal_iy = e_tl.iy
    --=
    self.timer = 0
    self.e_tl = e_tl
    self.max_y = max_y

    self.kinematic_jump = KinematicJump()
end

function St_NinjaJump:on_enter(e)
    e.c_move_hrz:off()
    e.c_gravity:off()
    e.c_b.vx = 0
    e.c_b.vy = 0
    --=
    e.is_grabbable=false
    e.is_catchable=false
    --=
    e.c_b.is_static = true
    e.c_b.filter = function(e, oth)
        return nil
    end
    --=
    self.timer = 0
    self.kinematic_jump:init(self.from_x, self.from_y, self.goal_x, self.goal_y, self.max_y)
    --=
    self.stance = 'jump'
end

function St_NinjaJump:updateTimerAndPos(slow_factor)
    slow_factor = slow_factor or (1 / 1.3)

    self.timer = self.timer + (love.timer.getDelta() * slow_factor)

    local x, y = -- = kinematic equation to get position
        self.kinematic_jump:getPos(self.timer)

    self.e.c_b:set_mid_x(x)
    self.e.c_b:set_bot(y)
end

function St_NinjaJump:evalKickHitHero(e)
    local dir=e.c_anim.dir
    local x1 = e.c_b:mid_x() - 14
    local x2 = e.c_b:mid_x() + 14
    local y1 = e.c_b:bot() - 24
    local y2 = e.c_b:bot() - 8

    local x, y, w, h = math.segToRect(x1, y1, x2, y2)

    local _, len = GAME.bump_world:queryRect(x, y, w, h, function(e) 
        return Xtype.is(e, E_Hero) and e.is_hittable
    end)

    if len > 0 then
        local pow_x = dir * Tl.Dim * 5
        local pow_y = -128

        GAME.e_hero.c_state_machine:set(
            St_HeroIsHit(GAME.e_hero, pow_x, pow_y)
        )
        GAME.e_hero.c_health:get_hit(1)
        self.trigger = true
    end
end

function St_NinjaJump:on_update(e, c_b)
    local e_hero = GAME.e_hero
    local map = GAME.map

    if self.stance == 'jump' then
        self:updateTimerAndPos(1)

        if e.c_pad:is_pressed('shuriken') and self:shootShuriken(e) then
            self.stance = 'shuriken'
        end

        if e.c_pad:is_pressed('jump_kick') then
            local kick_dir = c_b:mid_x() < e_hero.c_b:mid_x() and 1 or -1
            e.c_anim.dir = kick_dir
            e.c_anim:set('jump_kick')
            self.stance = 'jump_kick'

            -- local ix, iy = 
           
            -- e.c_anim:set('jump_kick')

        end
    elseif self.stance == 'jump_kick' then
        local e_target_tl = map:getNextGroundTile(map:cooToIndex(c_b:mid_x(), c_b:bot()))
        local reset_state = St_NinjaJump(e, e_target_tl and e_target_tl or self.e_tl, 24)
        
        if e_target_tl then
            reset_state.goal_x = c_b:mid_x() - e.c_anim.dir * 32
        else
            reset_state.goal_x = c_b:mid_x()
        end
        e.c_state_machine:force_set(reset_state)
        e.c_b.is_static = false
        e.c_b.filter = nil

        self:evalKickHitHero(e)


        -- local _, vy =
        --     self.kinematic_jump:getVel(self.timer)

        -- if vy > 0 and e.c_anim.is_over then
            -- local e_target_tl = GAME.map:getNextGroundTile(self.e)
            -- self:updateTimerAndPos(0.75)
            -- e.c_anim:set('ninja_fall')
        --     self.stance = 'jump'
        -- end

    elseif self.stance == 'shuriken' then

        e.c_b.vx = 0
        e.c_b.vy = 0
        e.c_anim.dir = self.shoot_dir

        local _, vy =
            self.kinematic_jump:getVel(self.timer)

        local jump_dy =
            self.kinematic_jump.dir_y

        if vy < 0 then
            self:updateTimerAndPos(0.75)
        elseif e.c_anim:is('shuriken') and e.c_anim.is_over then
            self:updateTimerAndPos(0.75)
            -- return St_NinjaJump(e, self.e_tl, 24)
        end

        if vy > 0 and e.c_anim:is('shuriken') and e.c_anim.is_over then
            e.c_anim:set('ninja_fall')
            self.stance = 'jump'
        end

    elseif self.on_landing then -- = just 1 frame
        -- return St_EnFall(e, 0.3)
        if c_b.is_on_ground then
            return St_EnDuck(e, 0.15)
        else
            return St_EnFall(e)
        end
    end

    -- = land => exit
    if self.timer >= self.kinematic_jump.t then
        c_b.vx = 0
        c_b.vy = 0
        c_b:set_bot(self.goal_y)
        self.on_landing = true
        self.stance = '' -- = just 1 frame
    end
end

function St_NinjaJump:on_exit(e)
    e.c_b.vx = 0
    e.c_b.vy = 0
    e.c_b.filter=nil
    e.c_move_hrz:on()
    e.c_gravity:on()
    e.is_grabbable = true
    e.is_catchable = true
    e.c_b.is_static = false
end

-- = check that ninja is not colliding with wall 
-- = then spawn shuriken
function St_NinjaJump:shootShuriken(e)
    local c_b = e.c_b
    local e_hero = GAME.e_hero

    if self.shuriken then
        return false
    end
    self.shuriken = true

    local shoot_dir = c_b:mid_x() < e_hero.c_b:mid_x() and 1 or -1
    local spawn_x   = c_b:mid_x() + shoot_dir * 16
    local spawn_y   = c_b:bot() - 26

    if GAME.map:isSolidAt(spawn_x, spawn_y) then
        return false
    end

    e.c_anim:set('shuriken')
    e.c_anim.dir = shoot_dir

    self.stance = 'shuriken'
    self.shoot_dir = shoot_dir

    local e_shuriken = E_Shuriken(spawn_x, spawn_y, e.c_anim.dir, 0, e)

    local adj   = math.abs(e_shuriken.c_b:mid_x() - e_hero.c_b:mid_x())
    local opp   = e_shuriken.c_b:mid_y() - e_hero.c_b:mid_y()
    local angle = math.atan2(opp, adj)

    e_shuriken.c_projectile.dir_x = math.cos(angle) * shoot_dir / 1.1
    e_shuriken.c_projectile.dir_y = -math.sin(angle) / 1.1

    GAME:add_e(e_shuriken)
    return true
end