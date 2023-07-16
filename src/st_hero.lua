local Tiny = Tiny or require 'lib.tiny'
local Gamera = Gamera or require 'lib.gamera'
local Game = Game or require 'game'

--===========================#
--

StateComp=Class('StateComp', Comp)

function StateComp:__construct(e)
    Comp.__construct(self, e)
    -- = callbacks
    self.try_enter=nil
    self.on_enter=nil
    self.on_update=nil
    self.on_exit=nil
    --=
    self.is_on_enter=false
    self.is_on_update=false
    self.is_on_exit=false
end

--===========================#
--

C_StateMachine=Class('C_StateMachine', Comp)

function C_StateMachine:__construct(e, StartStateCompClass--[[opt]] )
    Comp.__construct(self, e)
    --=
    self.__cur_state=nil
    self.__new_state=nil
    self.__concurrential_states = {}
    --=
    self.dbg_logs = false
    --=
    if StartStateCompClass then
        self:set(StartStateCompClass)
    end
end

function C_StateMachine:set(state_comp_instance)

    if state_comp_instance == {} then
        self.__new_state = {}
    elseif state_comp_instance == nil then
        self.__new_state = nil
    elseif Xtype.is(state_comp_instance, StateComp) then
        self.__new_state = state_comp_instance
        self.prev_state = self.__cur_state -- à surveiller
    end
end

function C_StateMachine:force_set(state_comp_instance)

    self:set(state_comp_instance)

    local e=self.e
    local c_sm=self
    local cur_state = c_sm.__cur_state

    if cur_state then
        cur_state.is_on_update=false
        cur_state.is_on_exit=true
    end

    if cur_state and Xtype.is(cur_state, StateComp) then
        local new_state = state_comp_instance

        if cur_state.on_exit then
            cur_state:on_exit(e, e.c_b, e.c_pad)
        end

        if new_state then -- conc state have prio
            c_sm.prev_state = cur_state
            new_state:on_enter(e, e.c_b, e.c_pad)
            cur_state = new_state
            c_sm.__cur_state = new_state
            cur_state.is_on_enter=true
            cur_state.is_on_update=true
        end
    end
end

function C_StateMachine:get() --[[: state_comp_instance ]]
    return self.__cur_state
end

-- function C_StateMachine:get_previous_state() --[[: state_comp_instance ]]
--     return self.__cur_state
-- end

function C_StateMachine:is(St_CompClass--[[StateCompClass]])
    return Xtype.is(self:get(), St_CompClass)
end

-- = concurrential states can force current state via try_enter callback
function C_StateMachine:add_concurrential_state(state_comp_instance)
    table.insert(self.__concurrential_states, state_comp_instance)
    return state_comp_instance
end

function C_StateMachine:clear_concurrential_states()
    self.__concurrential_states = {}
end

--===========================#
--

S_StateMachineUpdate=Tiny.processingSystem()
S_StateMachineUpdate.active=false;

function S_StateMachineUpdate:compare(e1, e2)
    if Xtype.is(e1, E_Hero) then
        return false
    elseif Xtype.is(e2, E_Hero) then
        return true
    else
        return e1 == e2
    end
end

function S_StateMachineUpdate:filter(e)
    return e:has_active('c_state_machine')
end

function S_StateMachineUpdate:process(e, dt)
    local c_sm=e.c_state_machine
    local cur_state = c_sm.__cur_state
    -- if (c_sm:is(St_EnIsHit)) then        
    --     print(cur_state, e.c_anim.cur_key, e.c_anim.timer, e.c_anim.frame_i, e.c_b.is_on_ground, e.c_b.vy, e.c_b.x, e.c_b.y)
    -- end
    if cur_state then
        cur_state.is_on_update=false
    end

    if cur_state and Xtype.is(cur_state, StateComp) then
        local new_state = nil
        -- = concurrential states can try force current state
        for _, conc_state in ipairs(c_sm.__concurrential_states) do
            if conc_state:try_enter(e, e.c_b, e.c_pad) then
                new_state = conc_state
            end
        end

        if new_state then -- conc state have prio
            cur_state:on_update(e, e.c_b, e.c_pad)
        else
            new_state = cur_state:on_update(e, e.c_b, e.c_pad)
        end

        cur_state.is_on_update=true

        if new_state then
            c_sm.prev_state = cur_state
            c_sm:set(new_state)
        end
    end
end

--===========================#
--

S_StateMachineSetNewState=Tiny.processingSystem()
S_StateMachineSetNewState.active=false;

function S_StateMachineSetNewState:compare(e1, e2)
    if Xtype.is(e1, E_Hero) then
        return false
    elseif Xtype.is(e2, E_Hero) then
        return true
    else
        return e1 == e2
    end
end

function S_StateMachineSetNewState:filter(e)
    return e:has_active('c_state_machine')
end

function S_StateMachineSetNewState:process(e, dt)
    local c_sm=e.c_state_machine
    local cur_state = c_sm.__cur_state
    local new_state = c_sm.__new_state

    -- = unset some events flags
    if cur_state then
        cur_state.is_on_exit=false
        cur_state.is_on_enter=false
    end
    if c_sm.__cur_state_ar then
        c_sm.__cur_state_ar.is_on_exit=false
        c_sm.__cur_state_ar = nil
    end
    
    if (new_state==nil or new_state=={} or Xtype.is(new_state, StateComp)) and new_state ~= cur_state then

        local dbg_log_fmt = '%-16s %-25s' -- log formatting

        if cur_state then
            if cur_state.on_exit then
                cur_state:on_exit(e, e.c_b, e.c_pad)
            end
            cur_state.is_on_exit=true
            cur_state.is_on_update=false
                        
            if c_sm.dbg_logs then -- log "on_exit"
                print( dbg_log_fmt:format('on_enter', Xtype.name(Xtype.get(cur_state)) or 'nil') )
            end
        end

        if new_state and new_state.on_enter then
            new_state:on_enter(e, e.c_b, e.c_pad)
            new_state.is_on_enter=true

            if c_sm.dbg_logs then -- log "on_enter"
                print( dbg_log_fmt:format('on_exit', Xtype.name(Xtype.get(cur_state)) or 'nil') ) 
            end
        end

        if c_sm.dbg_logs then -- log "set old_state => new_state"
            print( (dbg_log_fmt .. ' => %-30s'):format('on_set', Xtype.name(Xtype.get(cur_state)) or 'nil', Xtype.name(Xtype.get(new_state)) or 'nil'))
        end

        c_sm.__cur_state_ar = cur_state -- to unset on_exit
        c_sm.__cur_state = new_state
    end
end

--===========================#
--

St_HeroGround = Class('St_HeroGround', StateComp)

function St_HeroGround:__construct(e)
    StateComp.__construct(self, e)
    --=
end

function St_HeroGround:on_enter(e, c_b)
    e.c_b.vy = 0
    e:on('c_move_hrz', 'c_anim_dir')
    e:off('c_gravity')
    e.c_move_hrz:preset(Preset.C_Move_Hrz.St_Ground)
    e.c_move_hrz.max = HERO_RUN_SPEED
    self.conc_ladder_st = e.c_state_machine:add_concurrential_state(St_Ladder(e, St_Duck, St_HeroGround, St_HeroFall))
    self.conc_onguard_st = e.c_state_machine:add_concurrential_state(St_OnGuard1(e))

    e.c_b.is_platf_enabled=true
    -- e.c_b.is_ladder_enabled=true
    e.can_pick_enemy=true
    e.is_punchable = true
end

function St_HeroGround:isCeilingAbove(e, c_b)
    local _, len = GAME.bump_world:queryRect(
        c_b:left(),
        c_b:top()-16,
        c_b.w,
        16,
        function(e_oth)
            return Xtype.is(e_oth, E_Tile) and e_oth.c_tile:has_prop(Tl.Prop.Wall)
        end
    )
    return len > 0
end

function St_HeroGround:evalJumpSensitive(e, c_b, c_pad)
    local jump_high_impulse = CONST.HERO.JUMP.IMPULSE[1]
    local jump_high_threshold = 0.06
    local jump_delay = 0.15
    local jump_key = c_pad:get('a')
    local time_pressed = jump_key.time_pressed

    if Xtype.is(e.c_state_machine.prev_state, St_OnGuard2Combo) then
        if c_pad:is_pressed_once('a', jump_delay) then
            c_b.vy = jump_high_impulse
            return St_HeroFall(e)
        end
    end

    if c_pad:is_pressed2('a', jump_delay) or (time_pressed > jump_high_threshold and time_pressed < jump_delay) then
        -- = check if there is ceiling right above
        -- = prevent hero from jumping through ceiling
        if not self:isCeilingAbove(e, c_b) then
            if time_pressed >= jump_high_threshold then
                c_b.vy = jump_high_impulse
            else
                c_b.vy = -340
            end
            return St_HeroFall(e)
        end
    end
end

function St_HeroGround:evalJump(e, c_b, c_pad)
    local JMP_DELAY = 0.15
    local JMP_VY = CONST.HERO.JUMP.IMPULSE[1]

    if c_pad:is_pressed_once('a', JMP_DELAY) then
        if not self:isCeilingAbove(e, c_b) then
            c_b.vy = JMP_VY
            return true
        end
    end
end

function St_HeroGround:on_update(e, c_b, c_pad)
    if not e.c_health.hp == 0 then
       return St_HeroIsHit(e, -e.c_anim.dir*48, -148)
    end

    if  c_pad:is_pressed_once('a', 0.15) and GAME.is_lvl_clear then
        return St_GoNextLvl(e)
    end

    if not c_b.is_on_ground then
        return St_HeroFall(e)
     end

    local c_sm = e.c_state_machine
    if Xtype.is(c_sm.prev_state, St_Armlock) then
        if c_pad:is_pressed_once('down', 0.1) then
            return St_Duck(e)
        end
    else
        if c_pad:is_pressed('down') then -- and not Xtype.is(c_sm.prev_state, St_Armlock) then -- duck
            if IS_MOBILE then 
                if not c_pad:is_pressed('left') and not c_pad:is_pressed('right') then
                    return St_Duck(e)
                end
            else
                return St_Duck(e)
            end
        end
    end

    if self:evalJump(e, c_b, c_pad) then
        return St_HeroFall(e)
    end

    

    if c_pad:is_pressed('up') then
        e.guard_state_enabled = false
    else
        e.guard_state_enabled = true
    end

    local colls, _ = GAME.bump_world:queryRect(c_b:left()-6, c_b:bot()-18, c_b.w+12, 12, function(e_oth)
        return Xtype.is(e_oth, E_Enemy) and e_oth.c_b:bot() < c_b:bot()-4
    end)
    for i, e_target in ipairs(colls) do
        if e_target.c_b.vy > 0 and e_target.c_catchable and e_target.is_catchable then
            e_target.c_state_machine:set(St_EnOnGuard2(e_target, e))
            return St_OnGuard2(e, e_target)
        end
    end

    if love.keyboard.isDown('n') then -- = debug
        return St_GoNextLvl(e)
    end

    
end

function St_HeroGround:on_exit(e)
    e:off('c_move_hrz')
    e:off('c_gravity')
    e.c_state_machine:clear_concurrential_states()
    e.c_b.preset_jump = false
    e.is_punchable = false
end

--===========================#
--

St_HeroFall = Class('St_HeroFall', StateComp)

function St_HeroFall:__construct(e,pow_y)
    StateComp.__construct(self, e)
    --=
    if pow_y then
        e.c_b.vy = pow_y
    end
    self.jump_timer = 0
    self.is_jumping = e.c_b.vy < 0
end

function St_HeroFall:on_enter(e)
    e:on('c_move_hrz', 'c_anim_dir', 'c_gravity')
    e.c_move_hrz:preset(Preset.C_Move_Hrz.St_Jump)

    self.conc_ladder_st = e.c_state_machine:add_concurrential_state(St_Ladder(e, St_Duck, St_HeroGround, St_HeroFall))
    self.conc_platfm_st = e.c_state_machine:add_concurrential_state(St_HangToPlatf(e))
end

function St_HeroFall:collTestWithCornerWall(e, c_b, coll)
    local e_tl = coll.other
    local c_tl = e_tl.c_tile

    if c_b.vy > -64 and coll.normal.x ~= 0 and c_tl:has_prop(Tl.Prop.Wall) then
        local dir = -coll.normal.x

        local is_valid_x = 
            (dir == -1 and c_b:left()  >= e_tl.c_b:right() - 4) or
            (dir ==  1 and c_b:right() <= e_tl.c_b:left()  + 4)

        local is_valid_y = 
            (c_b:bot()-8 >= e_tl.c_b:top()) and
            (c_b:bot()-8 <= e_tl.c_b:bot())

        if is_valid_x and is_valid_y and GAME.map:is_corner(c_tl.index.x, c_tl.index.y, dir) then
            return St_ClimbCorner(e, e_tl, coll.normal.x)
        end
    end
end

-- function St_HeroFall:

function St_HeroFall:on_update(e, c_b, c_pad)
    local colls = c_b.colls
    local c_sm = e.c_state_machine

    -- c_b.fall_acc=Tl.Dim*68*love.timer.getDelta()
    c_b.fall_acc = CONST.HERO.JUMP.ACC[1]

    -- if c_b.vy < 0 then
        -- for i, col in ipairs(e.c_b.__colls_with_tile) do
        --     local e_tl = col.other
        --     GAME.map:destroy_tile(e_tl.ix, e_tl.iy)
        -- end
    -- end

    if c_b.has_hit_ground then
        -- return St_Duck(e, 0.07) -- que si max fall ?
        return St_HeroGround(e)
    end

    if c_b.can_stick_platf then
        return St_HangToPlatf(e,c_b.can_stick_platf.other)
    end

    -- = land on enemy
    if c_b.vy > 0 then
        local w = 28
        local h = 2
        local x = c_b:mid_x() - w * .5
        local y = c_b:bot() - 2

        local colls_with_enemies, _ = GAME.bump_world:queryRect(x, y, w, h, function(entity)
            return Xtype.is(entity, E_Enemy)
        end)

        for _, e_en in ipairs(colls_with_enemies) do
            if e_en.c_b.is_on_ground and e_en.is_hittable then --e_en.c_riddable then
                if c_b:bot() > e_en.c_b:bot()-22 and c_b:bot() < e_en.c_b:bot()-12 then
                    return St_LandOnEnemy(e, e_en);
                end
            end
        end
    end

    -- = meteor combo atk
    if c_b.vy < 0 then
        local w = 28
        local h = 2
        local x = c_b:mid_x() - w * .5
        local y = c_b:bot() - 2

        local colls_with_enemies, len = GAME.bump_world:queryRect(x, y, w, h, function(entity)
            return Xtype.is(entity, E_Enemy)
        end)

        for _, e_en in ipairs(colls_with_enemies) do
            if e_en.c_state_machine:is(St_EnIsHit) and e_en.c_catchable and e_en.is_catchable then
                if e_en.c_b.vy > -168 then 
                    return St_MeteorCombo(e, e_en)
                end
            end
        end
    end

    -- = climb corner edge
    if self.is_jumping  then
        for _, coll in ipairs(c_b.__colls_with_tile) do
            local climb_state = self:collTestWithCornerWall(e, c_b, coll)
            if climb_state then
                return climb_state
            end
        end        
    end

    -- = preset jump if hero is about to land
    if c_pad:is_pressed_once('a') and not c_b.preset_jump then
        local x = c_b:mid_x()
        local y = c_b:mid_y() + 80
        local e_tl = GAME.map:tile_at(x, y)
        if e_tl and e_tl.c_tile:has_prop(Tl.Prop.Ground) then
            c_b.preset_jump = true
        end
    end

    self.jump_timer = self.jump_timer + love.timer.getDelta()
    if not self.is_jumping
        and self.jump_timer <= 0.1
        and e.c_pad:is_pressed_once('a', 0.1)
        and not e.c_b.is_on_platform
        and not Xtype.is(c_sm.prev_state, St_Ladder)
        and not Xtype.is(c_sm.prev_state, St_ClimbPlatf)
        and not Xtype.is(c_sm.prev_state, St_HangToPlatf)
    then
        local _, len = GAME.bump_world:queryRect(
            c_b:left(),
            c_b:top()-16,
            c_b.w,
            16,
            function(e_oth)
                return Xtype.is(e_oth, E_Tile) and e_oth.c_tile:has_prop(Tl.Prop.Wall)
            end
        )
        if len == 0 then
            c_b.vy = CONST.HERO.JUMP.IMPULSE[1]
            return St_HeroFall(e)
        end
    end
end

function St_HeroFall:on_exit(e)
    e:off('c_move_hrz')
    e.c_state_machine:clear_concurrential_states()
    e.c_b.fall_acc=nil
end

--===========================#
--

St_Duck = Class('St_Duck', StateComp)

function St_Duck:__construct(e, timeout--[[ opt ]], skip_enter_anim--[[ opt ]])
    StateComp.__construct(self, e)
    --=
    self.timeout = timeout
    self.skip_enter_anim = skip_enter_anim or false
    self.timer = 0
end

function St_Duck:on_enter(e)
    e:off('c_move_hrz')
    e:off('c_gravity')
    self.timer = 0
    e.c_b.vx = 0
    e.c_b.vy = 0
    self.prev_h = e.c_b.h
    e.c_b:set_h(10)
    e.is_punchable = true
    self.conc_ladder_st = e.c_state_machine:add_concurrential_state(St_Ladder(e, St_Duck, St_HeroGround, St_HeroFall))
end

function St_Duck:on_update(e, c_b, c_pad)
    -- timed out state
    if self.timeout then
        self.timer = self.timer + love.timer.getDelta()
        if self.timer > self.timeout then return St_HeroGround(e) end
    end
    
    -- = stand back up
    if not self.timeout and not c_pad:is_pressed('down') then --
        for i, coll in ipairs(e.c_b.colls) do
            local e_oth = coll.other
            if 
                Xtype.is(e_oth, E_Enemy)
                and e.can_pick_enemy
                and e_oth.c_ground_pickable and e_oth.is_pickable
            then    
                e_oth.c_state_machine:set(St_EnOnGuard2(e_oth, e))
                return St_OnGuard2(e, e_oth)
            end
        end
        return St_HeroGround(e)
    end

    -- = armlock
    if not self.timeout and c_pad:is_pressed_once('a', 0.3) then
        local w = 24
        local h = 2
        local x = c_b:mid_x() - w * .5
        local y = c_b:bot() - 2

        local colls_with_enemies, len = GAME.bump_world:queryRect(x, y, w, h, function(entity)
            return Xtype.is(entity, E_Enemy) and entity.c_armlockable and entity.is_armlockable
        end)

        for _, e_en in ipairs(colls_with_enemies) do
            return St_Armlock(e, e_en)
        end
    end
    -- = go through platf
    if c_pad:is_pressed_once('a', 0.2) and c_b.is_on_platform then 
        local wall_colls = table.filter(c_b.ground_colls, function(e) 
            return e.c_tile:has_prop(Tl.Prop.Wall)
        end)

        if #wall_colls > 0 then
            local a = wall_colls[1]
            
            if math.abs(a.c_b:dist_x(e.c_b)) >= 16 then
                if a.c_b:mid_x() > e.c_b:mid_x() then
                    c_b:set_x(a.c_b:left() - c_b.w)
                else
                    c_b:set_x(a.c_b:right())
                end
                return St_HeroFall(e)
            end
        else
            return St_HeroFall(e)
        end
    end
end

function St_Duck:on_exit(e)
    e.c_b:set_h(Tl.Dim)
    e.c_state_machine:clear_concurrential_states()
end

--===========================#
--

St_Ladder = Class('St_Ladder', StateComp)

function St_Ladder:__construct(e, duck_state_Class, stand_state_Class, fall_state_Class)
    StateComp.__construct(self, e, e_tl)
    --=
    self.e_tl = e_tl or nil
    self.duck_state_Class = duck_state_Class
    self.fall_state_Class = fall_state_Class
    self.stand_state_Class = stand_state_Class
end

function St_Ladder:try_enter(e, c_b, c_pad)
    if c_pad:is_pressed('up') and e.c_ladder then-- and c_b.is_ladder_enabled) then
        local __colls_with_ladder, _ = GAME.bump_world:queryRect(c_b:mid_x() - 2, c_b:mid_y() - 10, 4, 10, function(item)
            return Xtype.is(item, E_Tile) and item.c_tile:has_prop(Tl.Prop.Ladder)
        end)
        if #__colls_with_ladder > 0 then
            local e_tl = __colls_with_ladder[1]
            if math.abs(c_b:mid_x() - e_tl.c_b:mid_x()) < 12 then
                self.e_tl = e_tl
                return true
            end
            return false
        end
    end

    local c_sm = e.c_state_machine

    -- = while ducking ?
    if c_b.is_on_ground and c_pad:is_pressed('down') then
        local __colls_with_ladder_below, _ = GAME.bump_world:queryRect(c_b:mid_x() - 2, c_b:bot(), 4, 10, function(item)
            return Xtype.is(item, E_Tile) and item.c_tile:has_prop(Tl.Prop.Ladder)
        end)
        local __colls_with_enemy, _ = GAME.bump_world:queryRect(c_b:mid_x() - 6, c_b:bot()-16, 6, 32, function(item)
            return Xtype.is(item, E_Enemy) and (item.c_state_machine:is(St_EnHitGround) or item.c_state_machine:is(St_EnIsHit))
        end)
        if #__colls_with_ladder_below > 0 then

            if Xtype.is(e, E_Enemy) or (Xtype.is(e, E_Hero) and #__colls_with_enemy == 0) or c_pad:get('down').time_pressed > 0.25 then
                local e_tl = __colls_with_ladder_below[1]
                
                if math.abs(c_b:mid_x() - e_tl.c_b:mid_x()) < 12 then
                    self.e_tl = e_tl
                    return true
                end
                return false
            end
        end
    end
end

function St_Ladder:on_enter(e, c_b)
    e:off('c_gravity')
    e:off('c_move_hrz')
    e.is_grabbable = false
    -- = ? pas terrible
    c_b.vx=0
    c_b.vy=0
    c_b.is_on_ground = false
    -- = pas terrible ?
    c_b:set_mid_x(self.e_tl.c_b:mid_x(), true)
    c_b:set_mid_y(self.e_tl.c_b:mid_y()-10, true)

    if Xtype.is(e, E_Hero) then
        self.h = c_b.h
        c_b:set_h(24)
    elseif  Xtype.is(e, E_Enemy) then
        -- e.is_hittable = false
    end
    GAME.tiny_world:refresh(e)

    if Xtype.is(e, E_Enemy) then
        self.speed_vy = ENEMY_LADDER_SPEED
    elseif Xtype.is(e, E_Hero) then
        self.speed_vy = 100
    end
end


function St_Ladder:on_update(e, c_b, c_pad)
    local release = false

    if self.on_landing then
        return self.duck_state_Class(e, 0.15)
    end

    if c_b.is_on_ground and c_pad:is_pressed('down') and c_b.vy > 0 then
        self.on_landing = true
    end

    if c_pad:is_pressed('up') then
        c_b.vy = -self.speed_vy
    elseif c_pad:is_pressed('down') then
        c_b.vy = self.speed_vy
    else
        c_b.vy = 0
    end
    
    --=
    if  Xtype.is(e, E_Hero) then
        for _, coll in ipairs(c_b.colls) do
        -- for _, e_en in ipairs(c_b.__colls_with['E_Enemy']) do
            if Xtype.is(coll.other, E_Enemy) then
                local e_en = coll.other

                if e_en.c_state_machine:is(St_Ladder) then
                    self.enemy_hit = e_en
                    e_en.c_state_machine:set(St_EnIsHit(e_en, 0, 0, true, false, false, {is_clean_landing = true}))
                    -- e_en.c_b:set_static(true)
                end
            end
        end
    end
    -- = check reach top
    if c_pad:is_pressed('up') then
        local __colls_with_top_ladder, _ = GAME.bump_world:queryRect(c_b:mid_x()-10, c_b:mid_y(), 20, 4, function(item)
            return Xtype.is(item, E_Tile) and item.c_tile:has_prop(Tl.Prop.Empty)
        end)

        if #__colls_with_top_ladder > 0 then
            local e_tl = __colls_with_top_ladder[1]
            c_b:set_bot(e_tl.c_b:bot())
           
            if e.c_pad:is_pressed('a') then
                return St_HeroGround(e)
            end
            if Xtype.is(e, E_Hero) then
                
                -- return self.stand_state_Class(e, 0.2)
                return self.duck_state_Class(e, 0.15)
            else
                return self.duck_state_Class(e, 0.2)
            end
        end
    end

    -- = ladder bottom end empty ?
    if c_b.vy > 0 then
        local empty_tl_below, _ = GAME.bump_world:queryRect(c_b:mid_x()-2, c_b:mid_y(), 4, 4, function(item)
            return Xtype.is(item, E_Tile) and item.c_tile:has_prop(Tl.Prop.Empty)
        end)
        release = #empty_tl_below > 0 -- ça bug
    end
    -- = is release position valid ?
    if c_pad:is_pressed_once('a') then
        local _, len = GAME.bump_world:queryRect(
            c_b:mid_x(),
            c_b:bot()-10,
            1,
            10,
            function(item)
                return Xtype.is(item, E_Tile) and item.c_tile:isSolid()
            end
        )
        release = (len == 0)
    end
    -- = Meteor combo
    if release and Xtype.is(e, E_Hero) then
        if self.enemy_hit then
            for _, coll in ipairs(c_b.colls) do
                if Xtype.is(coll.other, E_Enemy) then
                    local e_en = coll.other
                    
                    if e_en == self.enemy_hit then
                        e_en.c_b.vy = -128
                        return St_MeteorCombo(e, e_en, false)
                    end
                end
            end
        end
    end
    -- = release
    if release then
        return self.fall_state_Class(e)
    end
end

function St_Ladder:on_exit(e, c_b, c_pad)
    c_b.vy=0
    e.is_grabbable=true
    -- e.c_b.is_ladder_enabled = false
    c_b:set_h(self.h)
end

--===========================#
--

St_ClimbCorner = Class('St_ClimbCorner', StateComp)

function St_ClimbCorner:__construct(e, e_tl, normal_x)
    StateComp.__construct(self, e)
    --=
    self.e_tl = e_tl
    self.normal_x = normal_x

    self.goal_x = 0
    
    if normal_x == -1 then -- climber is facing right
        self.goal_x = e_tl.c_b:left() + e.c_b.w * .5
        e.c_anim.dir = 1
    else -- facing left
        e.c_anim.dir = -1
        self.goal_x = e_tl.c_b:right() - e.c_b.w * .5
    end
    
    self.goal_y = e_tl.c_b:top()
end

function St_ClimbCorner:on_enter(e, c_b)
    local e_tl = self.e_tl
    local c_anim = e.c_anim
    local c_b = e.c_b
    local normal_x = self.normal_x

    e:off('c_move_hrz')
    e:off('c_gravity')
    -- = set pos y
    c_b:set_top( e_tl.c_b:top() )
    c_b.vy = 0
    -- = set pos x
    if normal_x == -1 then
        local cur_frame=
            c_anim.props.frames[c_anim.frame_i];

        local ox = e_tl.c_b:left() - c_b:mid_x()
        local oy = (c_b:bot() - cur_frame.h) - e_tl.c_b:top() + 4

        c_anim:set('corner_climb', ox, oy)--1.05, 1.15)
        c_b:set_right( e_tl.c_b:left(), true )
    else
        local cur_frame=
            c_anim.props.frames[c_anim.frame_i];
        
        local ox =  c_b:mid_x() - e_tl.c_b:right()
        local oy = (c_b:bot() - cur_frame.h) - e_tl.c_b:top() + 4

        c_anim:set('corner_climb', ox, oy)--1.05, 1.15)
        c_b:set_left( e_tl.c_b:right(), true )
    end
end

function St_ClimbCorner:on_update(e, c_b, c_pad)
    local c_anim = e.c_anim

    if c_anim:get_frame() == 5 and GAME.cam.state == Gamera.State.Locked_On then
        GAME.cam:move_to(self.goal_x, self.goal_y, c_anim.props.duration - c_anim.timer - love.timer.getDelta()*2 )
    end

    if c_anim.is_over then
        local e_tl = self.e_tl

        if self.normal_x == -1 then -- climber is facing right 
            e.c_b:set_left(e_tl.c_b:left(), true)
        else -- facing left
            e.c_b:set_right(e_tl.c_b:right(), true)
        end
        -- = set pos y on top of wall
        -- print(self.goal_y,  e.c_b:bot())
        e.c_b:set_bot(self.goal_y, true)

        return St_HeroGround(e)
    end
end

function St_ClimbCorner:on_exit(e)
    local e_tl = self.e_tl

    if self.normal_x == -1 then -- climber is facing right 
        e.c_b:set_left(e_tl.c_b:left(), true)
    else -- facing left
        e.c_b:set_right(e_tl.c_b:right(), true)
    end
    -- = set pos y on top of wall
    e.c_b:set_bot(self.goal_y, true)

    GAME.cam:lock_on(e.c_b)
end


--===========================#
--

St_HangToPlatf = Class('St_HangToPlatf', StateComp)

function St_HangToPlatf:__construct(e, e_tl)
    StateComp.__construct(self, e)
    --=
    self.e_tl = e_tl
end

function St_HangToPlatf:try_enter(e, c_b)
end

function St_HangToPlatf:on_enter(e, c_b)
    local e_tl = self.e_tl

    e:on('c_move_hrz')
    e:off('c_gravity')
    e.c_move_hrz:preset(Preset.C_Move_Hrz.St_Platf)
    -- = set pos y
    e.c_b:set_top( e_tl.c_b:top() )
    e.c_b.vy = 0
    e.is_punchable = true
end

function St_HangToPlatf:on_update(e, c_b, c_pad)
    local release = false
    -- = release
    if c_pad:is_pressed_once('down') then
       release = true
    end
    -- = climb up
    if c_pad:is_pressed_once('up', 0.3) then
        return St_ClimbPlatf(e, self.e_tl)
    end
    -- = fall    
    local hover_platform_tl, _ = GAME.bump_world:queryRect(c_b:left(), c_b:top(), c_b.w, 4, function(item)
        return Xtype.is(item, E_Tile) and item.c_tile:has_prop(Tl.Prop.Platform)
    end)
    if #hover_platform_tl == 0 then
       release = true
    end

    if release then
        e.c_b.is_platf_enabled = false
        -- e.c_event_listener:once('has_hit_ground', function(e) e.c_b.is_platf_enabled=true end)
        return St_HeroFall(e)
    end
end

function St_HangToPlatf:on_exit(e)
    e:off('c_move_hrz')
end

--===========================#
--

St_ClimbPlatf = Class('St_ClimbPlatf', StateComp)

function St_ClimbPlatf:__construct(e, e_tl)
    StateComp.__construct(self, e)
    --=
    self.e_tl = e_tl
    self.goal_y = e_tl.c_b:top()
    self.timer = 0
end

function St_ClimbPlatf:on_enter(e, c_b)
    c_b.vx=0
    e.c_anim:set('platf_climb')
    GAME.cam:move_to(c_b:mid_x(), self.goal_y, e.c_anim.props.duration - love.timer.getAverageDelta() * 2)
end

function St_ClimbPlatf:on_update(e, c_b, c_pad)
    if e.c_anim:get_frame() == 2 and e.c_anim.enter_frame then
        self.h = e.c_b.h
        e.c_b:set_h(60)
    end
    if e.c_anim.is_over then
        self.timer = self.timer + love.timer.getDelta()
        if self.timer > 0.02 then
            return St_HeroGround(e)
        end
    end
end

function St_ClimbPlatf:on_exit(e, c_b, c_pad)
    e.c_b:set_h(self.h)
    c_b:set_bot(self.goal_y)
    GAME.cam:lock_on(c_b)
end

--===========================#
--

St_OnGuard1 = Class('St_OnGuard1', StateComp)

function St_OnGuard1:__construct(e, e_target)
    StateComp.__construct(self, e)
    --=
    self.e_target=e_target
end

function St_OnGuard1:try_enter(e, c_b)
    if e.guard_state_enabled == false then
        return false
    end
    for i, coll in ipairs(c_b.colls) do
        local oth = coll.other
        -- print(e.c_b.is_on_ground,oth.is_grabbable)
        if
            e.c_b.is_on_ground
            and Xtype.is(oth, E_Enemy)
            and oth.c_grabbable and oth.is_grabbable
        then
            local h_dir, h_x = e.c_anim.dir, e.c_b.x
            local e_dir, e_x = oth.c_anim.dir, oth.c_b.x

            if h_dir==e_dir 
                or (h_dir==1 and e_dir==-1 and h_x <= e_x+4) 
                or (h_dir==-1 and e_dir==1 and h_x >= e_x-4) 
            then
                self.e_target = oth
                return true
            end
        end
    end
end

function St_OnGuard1:on_enter(e, c_b)
    local e_target = self.e_target
    local h_x = e.c_b:mid_x()
    local e_x = e_target.c_b:mid_x()

    -- set positions
    e:off('c_move_hrz')
    e.c_b.vx=0
    e.c_b.vy=0
    -- e_target.c_state_machine:set(St_EnOnGuard1(self.e_target, e))
    e_target.c_state_machine:force_set(St_EnOnGuard1(self.e_target, e))
    e_target.c_b:set_bot(c_b:bot())
    e_target:off('c_move_hrz')
    e_target:off('c_gravity')
    e_target.c_b.vx=0
    e_target.c_b.vy=0

    if e_x < h_x then
        e.c_anim.dir = -1

        e_target.c_anim.dir = 1
        e_target.c_b:set_mid_x(e.c_b:mid_x() - 8)
    else
        e.c_anim.dir = 1

        e_target.c_anim.dir = -1
        e_target.c_b:set_mid_x(e.c_b:mid_x() + 8)
    end

    e.is_punchable = true
end

function St_OnGuard1:on_update(e, c_b, c_pad)
    local front = (c_pad:is_pressed_once('right') and e.c_anim.dir == 1) or (c_pad:is_pressed_once('left') and e.c_anim.dir == -1)
    local back = (c_pad:is_pressed_once('right') and e.c_anim.dir == -1) or (c_pad:is_pressed_once('left') and e.c_anim.dir == 1)

    if c_pad:is_pressed_once('up') then
        return St_OnGuard1Up(e, self.e_target)
    elseif front then
        return St_OnGuard1Front(e, self.e_target)
    elseif back then
        return St_OnGuard1Back(e, self.e_target)
    elseif c_pad:is_pressed_once('down') then
        self.e_target.c_state_machine:set(St_EnOnGuard2(self.e_target, e))
        return St_OnGuard2(e, self.e_target)
   end
end

function St_OnGuard1:on_exit(e, c_b, c_pad)
    -- self.e_target:on('c_move_hrz')
    -- self.e_target:on('c_gravity')
end

--===========================#
--

St_OnGuard1Up = Class('St_OnGuard1Up', StateComp)

function St_OnGuard1Up:__construct(e, e_target)
    StateComp.__construct(self, e)
    self.e_target = e_target
end

function St_OnGuard1Up:on_enter(e, c_b)
end

function St_OnGuard1Up:on_update(e, c_b, c_pad)
    if e.c_anim:get_frame() == 2 and e.c_anim.enter_frame then
        self.tgg = true
        local gravity = Tl.Dim * 36
        -- = initial_vy
        local pow_y = -Tl.Dim * 18.5
        -- = time from initial_vy to -initial_vy with gravity acc applied
        -- = time = 2 * initial_vy / gravity
        local t = 2 * pow_y / gravity
        -- = calc initial_vx to reach dist_x in time t
        local dist_x = Tl.Dim * 2.25
        local pow_x = e.c_anim.dir * (dist_x / t)
        --=
        self.e_target.c_state_machine:set(
            St_EnIsHit(self.e_target, pow_x, pow_y, true)
        )
        self.e_target.c_health:get_hit(4)
        self.e_target.jewel_color = E_Jewel.Color.Orange
    elseif e.c_anim.is_over then
        return St_HeroGetUp(e)
    end
end

--===========================#
--

St_HeroGetUp = Class('St_HeroGetUp', StateComp)

function St_HeroGetUp:__construct(e, e_target)
    StateComp.__construct(self, e)
end

function St_HeroGetUp:on_enter(e)
end

function St_HeroGetUp:on_update(e, c_b, c_pad)
    local frame_i = e.c_anim:get_frame()
    
    if e.c_anim.enter_frame and (frame_i == 2 or frame_i == 3) then
        e.c_b:set_mid_x(e.c_b:mid_x() - e.c_anim.dir * 2)
    end

    if e.c_anim.is_over then
        return St_HeroGround(e)
    end
end

--===========================#
--

St_OnGuard1Front = Class('St_OnGuard1Front', StateComp)

function St_OnGuard1Front:__construct(e, e_target)
    StateComp.__construct(self, e)
    self.e_target = e_target
end

function St_OnGuard1Front:on_enter(e, c_b) 
end

function St_OnGuard1Front:on_update(e, c_b, c_pad)
    local e_en = self.e_target
    local on_enter_frame = e.c_anim.enter_frame

    if on_enter_frame then
        local frame_i = e.c_anim:get_frame()

        if frame_i == 1 then
            -- e.c_b.vx = Tl.Dim * 0.8 * e.c_anim.dir
        end

        if frame_i == 3 then
            local pow_x = e.c_anim.dir * 30
            local pow_y = -100

            e_en.c_health:get_hit(6)
            e_en.c_state_machine:force_set(
                St_EnIsHit(e_en, pow_x, pow_y, false, false, false)
            )
            e_en.c_anim.dir = e.c_anim.dir

            e_en.jewel_color = E_Jewel.Color.Red

            -- = look for collisions with other enemies
            local e_closest = nil
            local e_hero_dir = e.c_anim.dir
            local w = 16
            local h = 8
            local x = 0
            local y =  e_en.c_b:mid_y()

            if e_hero_dir == 1 then
                x = e_en.c_b:mid_x()
            else
                x = e_en.c_b:mid_x() - w
            end
            -- GAME:debugDrawRect(x, y, w, h, {0,1,0}, 2)

            GAME.bump_world:queryRect(x, y, w, h, function(item)
                if Xtype.is(item, E_Enemy)
                    and item ~= e_en
                    and (
                        (e_hero_dir == 1 and item.c_b:mid_x() > e_en.c_b:mid_x()-2)
                        or (e_hero_dir == -1 and item.c_b:mid_x() < e_en.c_b:mid_x()+2)
                    )
                    and math.abs(e_en.c_b:mid_x() - item.c_b:mid_x()) < 18
                    and (
                        item.is_hittable_by_thrown or item.is_hittable
                    )
                then
                    -- = get closest enemy
                    if e_closest == nil then
                        e_closest = item
                    else
                        if math.abs(e_en.c_b:mid_x() - item.c_b:mid_x()) < math.abs(e_en.c_b:mid_x() - e_closest.c_b:mid_x()) then
                            e_closest = item
                        end
                    end
                end
            end)

            if e_closest then
                -- print('e_closest', e_closest)
                e_closest.c_state_machine:force_set(
                    St_EnIsHit(e_closest, pow_x, -70, false, false, false)
                )
                e_closest.c_anim.dir = e.c_anim.dir
            end
        end

        if frame_i == 4 then
            e.c_b.vx = 0
        end
    end

    if e.c_anim.is_over then
        return St_HeroGround(e)
    end
end

--===========================#
--

St_OnGuard1Back = Class('St_OnGuard1Back', StateComp)

function St_OnGuard1Back:__construct(e, e_target)
    StateComp.__construct(self, e)
    --=
    self.e_target = e_target
    --=
    
     
    -- self.pow_y = -Tl.Dim * 18
    -- print('pow_y', self.pow_y, t, self.pow_x, (distance_x * t))
    -- self.kinematic_jump = KinematicJump(e.c_b, , self.pow_y)
end

function St_OnGuard1Back:on_enter(e, c_b)
    e.c_anim:set('combo1_back')
    self.e_target.is_catchable = false
end

function St_OnGuard1Back:on_update(e, c_b, c_pad)
    local frame_i = e.c_anim:get_frame()
    local e_target = self.e_target

    if frame_i == 2 and e.c_anim.enter_frame then
        -- e_target.c_b:set_mid_x(
        --     e.c_b:mid_x() - e.c_anim.dir * 4
        -- )
        e_target.c_b:set_bot(
            e.c_b:bot()-6
        )
    elseif frame_i >= 3 and not self.tgg then
        self.tgg = true

        local gravity = Tl.Dim * 36
        -- = initial_vy
        local pow_y = -180
        -- = time from initial_vy to -initial_vy with gravity acc applied
        -- = time = 2 * initial_vy / gravity
        local t = 2 * pow_y / gravity
        -- = calc initial_vx to reach dist_x in time t
        local dist_x = Tl.Dim * 3.5
        local pow_x = e.c_anim.dir * (dist_x / t)
        --=
        e_target.c_state_machine:set(
            St_EnIsHit(e_target, pow_x, pow_y, false)
        )
        e_target.jewel_color = E_Jewel.Color.Blue
        e_target.c_health:get_hit(4)
    elseif e.c_anim.is_over then
        -- = exit
        return St_HeroGround(e)
    end
end

--===========================#
--

St_OnGuard2 = Class('St_OnGuard2', StateComp)

function St_OnGuard2:__construct(e, e_target)
    StateComp.__construct(self, e)
    --=
    self.e_target=e_target
end

function St_OnGuard2:on_enter(e, c_b)
    self.e_target.c_state_machine:set(St_EnOnGuard2(e_oth, e))
                
    e.c_anim:set('combo2_enter')
    -- e.c_move_hrz = C_MoveHrz(e)
    -- e.c_move_hrz:on()
    e.c_move_hrz:off()
    e.c_b.vx = e.c_anim.dir * 16
    e.is_punchable = true
end

function St_OnGuard2:on_update(e, c_b, c_pad)
    if not c_b.is_on_ground then
        return St_HeroFall(e)
     end

     if e.c_anim.cur_key == 'combo2_enter'  and e.c_anim.is_over then
        e.c_anim:set('combo2_idle')
        e.c_move_hrz:on():preset(Preset.C_Move_Hrz.St_Platf)
        e.c_b.vx = 0
    end

    if e.c_anim.cur_key ~= 'combo2_enter' then
        if c_b.vx ~= 0 then
            e.c_anim:set('combo2_walk')
        else
            e.c_anim:set('combo2_idle')
        end

        if c_pad:is_pressed_once('down', 0.2) then
            e.can_pick_enemy = false
            self.e_target.c_state_machine:set(St_EnIsHit(self.e_target, 0, 0, false, false, false))
            return St_Duck(e)
        end

        if c_pad:is_pressed_once('a', 0.3) then
            if c_pad:is_pressed('left') then
                e.c_anim.dir = -1
            elseif c_pad:is_pressed('right') then
                e.c_anim.dir = 1
            end
            return St_OnGuard2Combo(e, self.e_target)
        end

        if c_pad:is_pressed_once('up', 0.3) then
            self.e_target.c_state_machine:set(St_EnOnGuard3(self.e_target, e))
            return St_OnGuard3(e, self.e_target)
        end
    end
end

function St_OnGuard2:on_exit(e)
    e.c_move_hrz:off()
    e.c_b.vx = 0
end

--===========================#
--

St_OnGuard2Combo = Class('St_OnGuard2Combo', StateComp)

function St_OnGuard2Combo:__construct(e, e_target)
    StateComp.__construct(self, e)
    --=
    self.e_target=e_target
    self.trigger = false
end

function St_OnGuard2Combo:on_enter(e, c_b)
    e.c_move_hrz:off()
    e.c_b.vx = 0
end

function St_OnGuard2Combo:on_update(e, c_b, c_pad)
    local frame_i = e.c_anim:get_frame()
    local e_target = self.e_target
    if frame_i == 3 and e.c_anim.enter_frame then
        self.trigger = true

        local gravity = Tl.Dim * 30
        -- = initial_vy
        local pow_y = -160
        -- = time from initial_vy to -initial_vy with gravity acc applied
        -- = time = 2 * initial_vy / gravity
        local t = 2 * pow_y / gravity
        -- = calc initial_vx to reach dist_x in time t
        local dist_x = Tl.Dim * 4.75
        local pow_x = -e.c_anim.dir * (dist_x / t)
        self.e_target.c_state_machine:set(
            St_EnIsHit(self.e_target, pow_x, pow_y, true)
        )
        self.e_target.c_anim.dir = 1
        self.e_target.c_health:get_hit(4)
        self.e_target.jewel_color = E_Jewel.Color.Green
        self.e_target.bounce = true
    end
    
    if e.c_anim.is_over then
        return St_HeroGround(e)
    end
end

--===========================#
--
St_OnGuard3 = Class('St_OnGuard3', StateComp)

function St_OnGuard3:__construct(e, e_target, skip_enter_anim)
    StateComp.__construct(self, e)
    --=
    self.e_target=e_target
    self.skip_enter_anim = skip_enter_anim
    self.controls_enabled = false
    e.is_punchable = true
end

function St_OnGuard3:on_enter(e, c_b)
    if self.skip_enter_anim then
        e.c_anim:set('combo3_idle')
        e.c_move_hrz:on():preset(Preset.C_Move_Hrz.St_Platf)
        self.controls_enabled = true
    else
        e.c_anim:set('combo3_enter')
        e.c_move_hrz:off()
    end
end

function St_OnGuard3:on_update(e, c_b, c_pad)
    local e_en = self.e_target

    if not c_b.is_on_ground then
        return St_HeroFall(e)
    end

    -- print('=>', e.c_b.vx, e.c_b.vy)

    
    if e.c_anim.cur_key == 'combo3_enter'  then
        if  e.c_anim:get_progress_as_percent() >= 50 then
            self.controls_enabled = true
            e.c_move_hrz:on():preset(Preset.C_Move_Hrz.St_Platf)
        end

        if  e.c_anim.is_over then
            e.c_anim:set('combo3_idle')
            e.c_move_hrz:on():preset(Preset.C_Move_Hrz.St_Platf)
        end
    end

    if self.controls_enabled then
        if self.e_target.c_health.hp == 0 then
            return St_OnGuard3Down(e, self.e_target)
        end

        if c_b.vx ~= 0 then
            e.c_anim:set('combo3_walk')
        else
            e.c_anim:set('combo3_idle')
        end

        if c_pad:is_pressed('a') then
            return St_OnGuard3Kick(e, self.e_target)
        elseif c_pad:is_pressed_once('down', 0.3) then
            return St_OnGuard3Down(e, self.e_target)
        elseif c_pad:is_pressed_once('up', 0.2) then
            if c_pad:is_pressed('left') then
                e.c_anim.dir = -1
            elseif c_pad:is_pressed('right') then
                e.c_anim.dir = 1
            end
            return St_OnGuard3Up(e, self.e_target)
        end
    end

    -- e_en:off('c_anim_dir')
    -- e_en:off('c_anim')
    -- e_en.c_anim.dir = -e.c_anim.dir
    -- e_en.c_b:set_mid_x(e.c_b:mid_x() - e_en.c_anim.dir * 4)
    -- e_en.c_b.vx = e.c_b.vx
    -- e_en.c_b.vy = e.c_b.vy
end

function St_OnGuard3:on_exit(e, c_b)
    e.c_move_hrz:off()
    e.c_b.vx = 0
end

--===========================#
--

St_OnGuard3Kick = Class('St_OnGuard3Kick', StateComp)

function St_OnGuard3Kick:__construct(e, e_target)
    StateComp.__construct(self, e)
    --=
    self.e_target = e_target
end


function St_OnGuard3Kick:on_enter(e, c_b)
    e.c_anim:set('combo3_kick')

    -- self.e_target.c_anim:set('combo3_kicked')

end

function St_OnGuard3Kick:on_update(e, c_b, c_pad)
    self.e_target:off('c_anim')
    
    -- if e.c_anim:get_frame() == 1 and e.c_anim.enter_frame then
        -- self.e_target.c_anim.shader = SHADER_IS_HIT
        -- Timer.after(0.05, function() self.e_target.c_anim.shader = nil end)
    -- end

    if e.c_anim.is_over then        
        self.e_target.c_health:get_hit(1.5)
        
        self.e_target.jewel_color = E_Jewel.Color.Cyan
        return St_OnGuard3(e, self.e_target, true)
    end
end

function St_OnGuard3Kick:on_exit(e, c_b, c_pad)
    self.e_target:on('c_anim')
end

--===========================#
--

St_OnGuard3Down = Class('St_OnGuard3Down', StateComp)

function St_OnGuard3Down:__construct(e, e_target)
    StateComp.__construct(self, e)
    --=
    self.e_target = e_target
end

function St_OnGuard3Down:on_enter(e, c_b)
    self.e_target.c_state_machine:set(nil)
    e.c_anim:set('combo3_d')
    -- print('ici')
end

function St_OnGuard3Down:on_update(e, c_b, c_pad)
    if e.c_anim.frame_i == 1 and e.c_anim.enter_frame then
        self.e_target.c_anim:set('gethit')
        self.e_target.c_b:set_mid_x(c_b:mid_x() - e.c_anim.dir * 10)
    end

    if e.c_anim.frame_i == 2 and e.c_anim.enter_frame then
        local pow_x = -e.c_anim.dir * Tl.Dim * 1.5
        self.e_target.c_state_machine:set(St_EnIsHit(self.e_target, pow_x, -60, false))
    end

    if e.c_anim.is_over then
        return St_HeroGround(e)
    end
end

--===========================#
--

St_OnGuard3Up = Class('St_OnGuard3Up', StateComp)

function St_OnGuard3Up:__construct(e, e_target)
    StateComp.__construct(self, e)
    self.e_target = e_target
end

function St_OnGuard3Up:on_enter(e, c_b)
end

function St_OnGuard3Up:on_update(e, c_b, c_pad)
    if e.c_anim.frame_i == 4 and not self.trigger then
        self.trigger = true
       
        local gravity = Tl.Dim * 36
        -- = initial_vy
        local pow_y = -490
        -- = time from initial_vy to -initial_vy with gravity acc applied
        -- = time = 2 * initial_vy / gravity
        local t = 2 * pow_y / gravity
        -- = calc initial_vx to reach dist_x in time t
        local dist_x = Tl.Dim * 5.5
        local pow_x = -e.c_anim.dir * (dist_x / t)
        local new_state = St_EnIsHit(self.e_target, pow_x, pow_y, true)
        new_state.break_wall = false
        self.e_target.c_state_machine:set(
            new_state
        )
        self.e_target.c_health:get_hit(4)
    end
    if e.c_anim.is_over then
        return St_HeroGround(e)
    end
end

--===========================#
--

St_MeteorCombo = Class('St_MeteorCombo', StateComp)

function St_MeteorCombo:__construct(e, e_target, powy_enabled)
    StateComp.__construct(self, e)
    --=
    self.e_target = e_target
    self.e_target_csm = e_target.c_state_machine
    -- print(powy_enabled)
    if powy_enabled == nil then
        self.powy_enabled = true
    else 
        self.powy_enabled = powy_enabled
    end
    self.break_count = 0
    self.break_chance = 60
end

function St_MeteorCombo:on_enter(e, c_b)
    self.e_target_csm:force_set(St_EnMeteorCombo(self.e_target, e))
    e.c_gravity:on()
    e.c_move_hrz:off()

    local new_x = (e.c_b:mid_x() + self.e_target.c_b:mid_x()) / 2
    e.c_b:set_mid_x(new_x)
    self.e_target.c_b:set_mid_x(new_x)
    -- e.c_b:set_mid_x(self.e_target.c_b:mid_x())
    -- self.old_w = e.c_b.w
    -- e.c_b:set_w(4)
    local gravity = Tl.Dim * 36
    local initial_y = c_b:bot()
    local final_y = nil

    if self.powy_enabled then
        final_y = initial_y - 128
    end

    if not self.powy_enabled then
        final_y = initial_y - 32
    end
    -- = get initial_vy in order to get to -400px above initial_y at final_vy = 0
    -- = take into account gravity. gravity = 36px/s²
    c_b.vy = -math.sqrt(2 * gravity * (initial_y - final_y))

    c_b.fall_max = Tl.Dim*1000
    e.c_anim:set('combo_meteor')
end

function St_MeteorCombo:on_hit_ground(e, c_b, e_target)
    e_target.c_health:get_hit(12)

    GAME.cam:shake(0.4, 14)
    GAME:heroLandImpact(c_b:mid_x(), c_b:mid_y())
end

function St_MeteorCombo:on_update(e, c_b, c_pad)
    local e_target = self.e_target

    c_b.fall_acc = Tl.Dim*80
    -- = if ground is platform, there is a chance to break it
    local break_ground = false
    if c_b.is_on_ground and c_b.is_on_platform and #c_b.ground_colls == 1 and c_b.vy >= 0 then
        local rand = math.random(1, 100)
        -- print(rand, self.break_chance)
        if rand <= self.break_chance then
            GAME.map:destroy_tile(c_b.e_ground_tl.ix, c_b.e_ground_tl.iy, 0)
            break_ground = true
        end
    end

    if break_ground then
        local vy = self.vy
        Timer.after(0.03, function() 
            c_b.vy = vy
            e.c_gravity:on()
        end)
        self.break_chance = self.break_chance - 20
    end

    if c_b.is_on_ground and not break_ground then
        local pow_x = e.c_anim.dir * 64
        local pow_y = -256

        e_target.c_state_machine:set(St_EnIsHit(e_target, pow_x, pow_y, false))
        e_target.jewel_color = E_Jewel.Color.Purple

        self:on_hit_ground(e, c_b, e_target)

        return St_Duck(e, 0.3)
    else
    --     if c_pad:is_pressed_once('a') or c_b.vy > 0 then
    --         e.c_move_hrz:off()
    --         e.c_b.vx = 0
    --     end
        e_target.c_b:set_vec(0,0)
        e_target.c_b:set_mid(c_b:mid_x(), c_b:mid_y())
    end

    self.vy = c_b.vy
end

function St_MeteorCombo:on_exit(e, c_b)
    c_b.fall_acc = nil
    c_b.fall_max = nil
    -- e.c_b:set_w(self.old_w)
end


--===========================#
--

St_Armlock = Class('St_Armlock', StateComp)

function St_Armlock:__construct(e, e_target)
    StateComp.__construct(self, e)
    --=
    self.e_target = e_target
    self.timeout = 0.25
end

function St_Armlock:on_enter(e, c_b)
    local e_en = self.e_target
    
    e.c_anim:set('combo_armlock')
    
    -- self.e_target.c_anim.timer = 0

    -- e_en.c_anim:play()

    e_en.c_anim:set_frame(3)
    e_en.c_anim:pause()

    if e_en.c_anim.dir == -1 then
        e.c_b:set_mid_x(self.e_target.c_b:mid_x()+10)
    else
        e.c_b:set_mid_x(self.e_target.c_b:mid_x()-10)
    end
    
    e.c_anim.dir = e_en.c_anim.dir
end

function St_Armlock:on_update(e, c_b, c_pad)
    self.e_target.c_anim:pause()

    if e.c_anim:get_frame() == 5 and e.c_anim.enter_frame then
        GAME.cam:shake(0.1, 2)
        self.e_target.jewel_color = E_Jewel.Color.Pink
        self.e_target.c_anim:set('armlock'):set_origin(nil, -6)
        self.e_target.c_health:get_hit(6)
        self.e_target.c_anim.shader = SHADER_IS_HIT
        Timer.after(0.15, function() self.e_target.c_anim.shader = nil end)
    end

    if e.c_anim.is_over then
        self.e_target.c_anim:set('hit_ground'):set_origin(nil, -6)
        return St_HeroGround(e)
    end
end

--===========================#
--

St_LandOnEnemy = Class('St_LandOnEnemy', StateComp)

function St_LandOnEnemy:__construct(e, e_en)
    StateComp.__construct(self, e)
    --=
    self.e_en = e_en
end

function St_LandOnEnemy:on_enter(e, c_b, c_pad)
    local e_en = self.e_en

    e.c_anim:set('onen_enter')
    e.c_anim:set_origin(nil, -12)

    -- e_en.c_state_machine:set(nil)
    e_en.c_state_machine:force_set(nil)
    e_en.c_anim.dir = e.c_anim.dir
    e_en.c_anim:set('hero_landing_over')
    e_en.is_carrying_hero=true
end

function St_LandOnEnemy:on_update(e, c_b, c_pad)
    local e_en = self.e_en

    e_en.c_anim.dir = e.c_anim.dir

    e.c_b:set_mid_x(e_en.c_b:mid_x())
    e.c_b:set_bot(e_en.c_b:bot()-18)

    if e_en.c_anim:is('hero_landing_over') == false then
        e_en.c_anim:set('hero_landing_over')
    end

    if (e.c_anim:get_progress_as_percent() >= 20 and (
        e.c_pad:is_pressed_once('down', 0.2) or e.c_pad:is_pressed_once('up', 0.2)) )then
        return St_IdleOverEnemy(e, e_en, false)
    end

    if e.c_anim.is_over then
        return St_IdleOverEnemy(e, e_en, false)
    end
end

function St_LandOnEnemy:on_exit(e, c_b)
    self.e_en.is_carrying_hero=false
end

--===========================#
--

St_IdleOverEnemy = Class('St_IdleOverEnemy', StateComp)

function St_IdleOverEnemy:__construct(e, e_en, skip_enter_anim)
    StateComp.__construct(self, e)
    --=
    self.e_en = e_en
end

function St_IdleOverEnemy:on_enter(e, c_b, c_pad)
    local e_en = self.e_en

    e.c_anim:set('onen_idle')
    e.is_punchable = true
    if Xtype.is(e.c_state_machine.prev_state, St_LandOnEnemy) then
        e_en.c_state_machine:force_set(St_EnGround(e_en))
    end
    e_en.is_carrying_hero=true
    self.e_en_prev_w = e_en.c_b.w
    e_en.c_b:set_w(c_b.w)
end

function St_IdleOverEnemy:is_facing_wall(c_b, dir)
    local x = c_b:mid_x()+dir*(Tl.Dim+4)
    local y = c_b:bot()
    local e_tl = GAME.map:tile_at(x, y)
    return e_tl and e_tl.c_tile:has_prop(Tl.Prop.Wall)
end

function St_IdleOverEnemy:is_facing_edge(c_b, dir)
    local x = c_b:mid_x()
    local y = c_b:bot()+Tl.Dim
    local ix, iy = GAME.map:to_index(x, y)
    return GAME.map:is_corner(ix, iy, -dir)
end

function St_IdleOverEnemy:on_update(e, c_b, c_pad)
    local e_en = self.e_en

    e.c_b:set_mid_x(e_en.c_b:mid_x())
    e.c_b:set_bot(e_en.c_b:bot()-18)

    if self.e_en.c_health.hp == 0 then
        e_en.c_state_machine:set(St_EnIsHit(e_en, false, false, false));
        return St_HeroFall(e, 0)
    end

    -- e.c_b:set_mid_y(e_en.c_b:top())

    e.c_anim.dir = e_en.c_anim.dir

    if c_pad:is_pressed_once('up') then
        return St_HeroFall(e, -200)
    
    elseif c_pad:is_pressed('down', 0.2) then

        local dir = nil
        local is_facing_obstacle = nil 

        if c_pad:is_pressed('right') then
            dir = 1
            is_facing_obstacle = 
                self:is_facing_edge(c_b, dir) or self:is_facing_wall(c_b, dir)
        elseif c_pad:is_pressed('left') then
            dir = -1
            is_facing_obstacle = 
                self:is_facing_edge(c_b, dir) or self:is_facing_wall(c_b, dir)
        else
            dir = e.c_anim.dir
            is_facing_obstacle = self:is_facing_edge(c_b, dir) or self:is_facing_wall(c_b, dir)
        end

        if not is_facing_obstacle then
            return St_IdleOverEnemyThrow(e, e_en)
        end
    elseif c_pad:is_pressed('a') then
        return St_IdleOverEnemyPunch(e, e_en)
    end
end

function St_IdleOverEnemy:on_exit(e, c_b)
    self.e_en.is_carrying_hero=false
    self.e_en.c_b:set_w(self.e_en_prev_w)
end


--===========================#
--

St_IdleOverEnemyThrow = Class('St_IdleOverEnemyThrow', StateComp)

function St_IdleOverEnemyThrow:__construct(e, e_en)
    StateComp.__construct(self, e)
    self.e_en = e_en
end

function St_IdleOverEnemyThrow:on_enter(e, c_b, c_pad)
    local e_en = self.e_en

    e_en.c_state_machine:set(nil)

    if c_pad:is_pressed('right') then
        e.c_anim.dir = 1
        e_en.c_anim.dir = 1
    elseif c_pad:is_pressed('left') then
        e.c_anim.dir =-1
        e_en.c_anim.dir = -1
    end

    e.c_gravity:on()
    e.c_b.vx = 0

    self.goal_x = e.c_b:mid_x() + e_en.c_anim.dir * 30
    self.goal_y = e_en.c_b:bot()
    self.e_en.is_carrying_hero=true
end

function St_IdleOverEnemyThrow:on_update(e, c_b, c_pad)
    local e_en = self.e_en
    local frame_i = e.c_anim.frame_i

    if e_en.c_state_machine:get() == nil then
        -- e_en.c_anim:set('on_hero_over_throw')
    end

    if c_b.has_hit_ground then
        e.c_gravity:off()
        e.c_b.vy = 0
        e.is_punchable = false
    end

    if e.c_anim.enter_frame then
        if frame_i == 2 then
            GAME.cam:move_to(self.goal_x, self.goal_y, e.c_anim.props.duration - e.c_anim.timer - love.timer.getDelta()*2 )

            -- e.c_b.vx = e.c_anim.dir * 38 / e.c_anim.duration
        elseif frame_i == 10 then
            -- e.c_b.vx = 0
        end
    end

    if e.c_anim.frame_i == 6 and not self.trig1 then
        self.trig1 = true

        local gravity = Tl.Dim * 36
        -- = initial_vy
        local pow_y = -220
        -- = time from initial_vy to -initial_vy with gravity acc applied
        -- = time = 2 * initial_vy / gravity
        local t = 2 * pow_y / gravity
        -- = calc initial_vx to reach dist_x in time t
        local dist_x = Tl.Dim * 4
        local pow_x = -e.c_anim.dir * (dist_x / t)
        --=
        self.e_en.c_state_machine:set(
            St_EnIsHit(self.e_en, pow_x, pow_y, true)
        )
        self.e_en.c_health:get_hit(7.5)
        self.e_en.jewel_color = E_Jewel.Color.Yellow
        
        -- = get enemies arround and hit them
        Game:onEnemyThrowComboImpact(self.e_en)
        self.e_en.c_anim.shader = SHADER_IS_HIT
        Timer.after(0.1, function() self.e_en.c_anim.shader = nil end)
    end

    if e.c_anim.is_over then
        e.c_b:set_mid_x(self.goal_x)
        return St_HeroGround(e)
    end
end

function St_IdleOverEnemyThrow:on_exit(e, c_b)
    GAME.cam:lock_on(e.c_b)
end

--===========================#
--

St_IdleOverEnemyPunch = Class('St_IdleOverEnemyPunch', StateComp)

function St_IdleOverEnemyPunch:__construct(e, e_en)
    StateComp.__construct(self, e)
    --=
    self.e_en = e_en
end

function St_IdleOverEnemyPunch:on_enter(e, c_b)
    local e_en=self.e_en
    e.c_anim:set('onen_punch')
    self.e_en.is_carrying_hero=true

    -- e.c_anim:set_origin(nil, 0.53)
    e_en.c_anim.shader = SHADER_IS_HIT
    Timer.after(0.05, function() e_en.c_anim.shader = nil end)
    e.c_gravity:off()
    e.c_b.vy = 0
    self.old_en_w = e_en.c_b.w
    e_en.c_b:set_w(c_b.w)
end

function St_IdleOverEnemyPunch:on_update(e, c_b, c_pad)
    local e_en=self.e_en
    e.c_b:set_mid_x(e_en.c_b:mid_x())

    if (e.c_anim.frame_i == 2 and not self.trigger) then
        -- e_en.c_state_machine:set(nil)
        -- e_en.c_anim:set('on_hero_over_punch')
        self.e_en.c_health:get_hit(1.5)
        self.e_en.jewel_color = E_Jewel.Color.Cyan
        self.trigger=true
    end

    if e.c_anim.is_over then
        e_en.c_b:set_w(self.old_en_w)
        return St_IdleOverEnemy(e, self.e_en, true)
    end
end

--===========================#
--

St_HeroIsHit = Class('St_HeroIsHit', StateComp)

function St_HeroIsHit:__construct(e, pow_x, pow_y)
    StateComp.__construct(self, e)
    --=
    self.pow_x = pow_x or 0
    self.pow_y = pow_y or 0
end

function St_HeroIsHit:applyOnHitShader(e)
    -- = on-hit shader effect
    e.c_anim.shader = SHADER_IS_HIT
    Timer.after(0.075, function() e.c_anim.shader = nil end)
end

function St_HeroIsHit:on_enter(e, c_b)
    e.c_anim:set('get_hit')
    e:on('c_gravity')
    -- print('St_HeroIsHit:on_enter')

    e.c_b.vx = self.pow_x
    e.c_b.vy = self.pow_y
    -- print('pow', self.pow_x, self.pow_y)
    e.c_anim_dir:off()
    e.is_hittable = false
    e.is_shockable = true
    e.is_grabbable = false
    e.is_punchable = false
    self:applyOnHitShader(e)
end

function St_HeroIsHit:on_update(e, c_b, c_pad)
    -- print('St_HeroIsHit:on_update', e.c_b.has_hit_ground)
    e.c_anim.dir = self.pow_x < 0 and 1 or -1
    -- print('vxy', e.c_b.vx, e.c_b.vy)
    if e.c_b.has_hit_ground then
        if e.c_health.hp == 0 then
            return St_HeroDead(e)
        else
            e.is_hittable=true
            e.c_anim.dir = e.c_b.vx < 0 and -1 or 1
            return St_Duck(e, 0.1)
            -- return St_HeroGround(e)
        end
    end
end



--===========================#
--

St_HeroDead = Class('St_HeroDead', StateComp)

function St_HeroDead:__construct(e, pow_x, pow_y)
    StateComp.__construct(self, e)
    --=
end

function St_HeroDead:on_enter(e, c_b)
    e.c_anim:set('get_hit')
    e.c_gravity:off()
    e.c_b.vx = 0
    e.c_b.vy = 0

    e.is_hittable = false
    e.is_grabbable = false

    e.c_anim:set('hit_ground'):set_origin(nil, -6)
    e.c_move_hrz:off()
end

function St_HeroDead:on_update(e, c_b, c_pad)
end

--===========================#
--

St_GoNextLvl = Class('St_GoNextLvl', StateComp)

function St_GoNextLvl:__construct(e)
    StateComp.__construct(self, e)

    self.map = GAME.map
    self.map_w = (self.map.iw * Tl.Dim)
    --=
    self.next_map_x = self.map.x + self.map_w * 3
    self.goal_x = self.next_map_x + Tl.Dim*4.5-- + Tl.Dim * math.random(1, 2)
    self.goal_y = -Tl.Dim * 3
    self.dist_x = self.goal_x - e.c_b:mid_x()
    self.load_next_lvl = false
    self.on_landing = false
end

-- function St_GoNextLvl:on_enter(e)
--     -- e.is_grabbable=false
--     -- e.is_catchable=false
--     e.c_b.filter = function(e, oth)
--         if Xtype.is(oth, E_Tile) then
--             if oth.c_tile:has_prop(Tl.Prop.Wall) then
--                 return 'cross'
--             end
--         end
--     end
--     e.c_anim.dir = 1
--     e.c_anim:set('jump')
--     e.c_move_hrz:off()
--     e.c_gravity:off()
--     e.c_b.vx = 0
--     e.c_b.vy = 0

--     self.timer = 0
--     self.v = 0 -- 
--     self.a = 60 * Tl.Dim
--     self.t = nil -- unknown
--     self.u = nil -- unknown

--     self.s = (-15 - math.random(3)) * Tl.Dim 
--     if self.s < -self.map.h then
--         self.s = -self.map.h
--     end

--     self.u = -math.sqrt(self.v^2 - 2*self.a*self.s)
--     self.t_top = -(self.u - self.v) / self.a

--     -- kinematic equation : jump time
--     --
--     -- jump time to top
--     -- t = -(u - v) / a 
--     --
--     -- jump time to ground
--     -- s = ut + 1/2at^2
--     -- 0 = ut + 1/2at^2 - s
--     -- 0 = (1/2at^2) + ut - s
--     -- 0 = ax^2 + bx + c 
--     -- x <=> t

--     local a = 0.5 * self.a
--     local b = self.u
--     local c = e.c_b:bot() - self.goal_y

--     self.t = (-b + math.sqrt(b^2 - 4*a*c)) / (2*a)
-- end

-- function St_GoNextLvl:on_update(e, c_b)
--     local dt = love.timer.getDelta()
--     self.timer = self.timer + dt

--     c_b.vy = self.u + self.a * self.timer
--     c_b.vx = self.dist_x / self.t

--     -- local sc = GAME.world.sc - (self.t_top  - math.abs(self.timer  - self.t_top ))
--     -- if sc <  GAME.world.sc - 0.4 then
--     --     sc = GAME.world.sc - 0.4
--     -- end
--     -- GAME.cam:setScale(sc)
--     -- print(sc)
--     for i, col in ipairs(e.c_b.__colls_with_tile) do
--         local e_tl = col.other
--         if e_tl.c_b:bot() < self.goal_y then
--             if e_tl.ix ~= 1 or e_tl.iy < GAME.map.ih - 5 then -- = ne pas détruire si x=1 et y>ih-5
--                 GAME.map:destroy_tile(e_tl.ix, e_tl.iy, col.normal.x)
--             end
--         end
--     end

--     if self.on_landing then
--         -- return St_Duck(e, 0.2)
--     end

--     if self.timer >= self.t then
--         c_b.vx = 0
--         c_b.vy = 0
--         -- c_b:set_mid_x(self.goal_x)
--         -- c_b:set_bot(self.goal_y)
--         -- c_b:set_bot(-Tl.Dim * 3)
--         -- GAME.cam:setScale(GAME.world.sc)
--         -- GAME.cam:shake(0.4, 14)
--         -- GAME:heroLandImpact(c_b:mid_x(), c_b:bot())
--         -- GameSignal:landNewLevel()
--         -- self.on_landing = true
--         e.c_move_hrz:off()
--         return St_Duck(e, 0.2)
--     end

--     if c_b.vy >= 0 and self.load_next_lvl == false then
--         self.load_next_lvl = true
--         GAME:load_level(GAME.level+1, self.next_map_x)
--     end
-- end

-- function St_GoNextLvl:on_exit(e)
--     e.c_b.filter=nil
--     e.c_move_hrz:on()
--     e.c_gravity:on()
-- end


function St_GoNextLvl:__construct(e)
    StateComp.__construct(self, e)
    self.timer = 0

    self.map = GAME.map
    self.map_w = (self.map.iw * Tl.Dim)
    -- --=
    self.next_map_x = self.map.x + self.map_w * 2
    self.start_x = e.c_b:mid_x()
    self.goal_x = self.next_map_x + Tl.Dim * 4.5-- + Tl.Dim * math.random(1, 2)
    self.goal_y = -Tl.Dim * 3
    -- self.dist_x = self.goal_x - e.c_b:mid_x()
    self.load_next_lvl = false
    self.on_landing = false
    --=
    self.dist_x = self.goal_x - e.c_b:mid_x()
    
    --=
    self.dir_x = 1
    -- print(self.goal_x, self.goal_y, self.dist_x)

end

function St_GoNextLvl:on_enter(e)
    self.timer = 0
    e.c_anim.dir = 1
    e.c_move_hrz:off()
    e.c_gravity:off()
    e.c_b.vx = 0
    e.c_b.vy = 0
    -- e.is_grabbable=false
    -- e.is_catchable=false
    -- e.c_b.filter = function(e, oth)
    --     if Xtype.is(oth, E_Tile) then
    --         if oth.c_tile:has_prop(Tl.Prop.Wall) then
    --             return 'cross'
    --         end
    --     end
    -- end
    e.c_b.filter = function(e, oth)
        return nil
    end

    -- use kinematic equation to find initial velocity
    -- in order to reach the goal_y in the given time
    -- with a given acceleration

    self.acc = Tl.Dim * 50
    self.t = 1.5
    self.init_vel = (self.goal_y - e.c_b:bot()) / self.t - 0.5 * self.acc * self.t
    print(self.init_vel)
    e.c_b.vy = self.init_vel
end

function St_GoNextLvl:on_update(e, c_b)
    -- e.c_move_hrz:off()
    -- e.c_gravity:off()
    if self.timer < self.t then
        local dt = love.timer.getDelta()

        self.timer = self.timer + dt
        if self.timer > self.t then self.timer = self.t end


        c_b:set_mid_x(self.start_x + self.dist_x * self.timer / self.t)
        e.c_b.vy = e.c_b.vy + self.acc * dt

        -- local initial_velocity
    end

    if self.on_landing then
        return St_Duck(e, 0.2)
    end

    if self.timer >= self.t and not self.on_landing then
        c_b.vx = 0
        c_b.vy = 0
        self.on_landing = true
        e.c_b:set_mid_x(self.goal_x)
        e.c_b:set_bot(self.goal_y)
        GAME.cam:setScale(GAME.world.sc)
        GAME.cam:shake(0.4, 14)
        GAME:heroLandImpact(c_b:mid_x(), c_b:bot())
        -- GameSignal:landNewLevel()
    end

    if c_b.vy >= 0 and self.load_next_lvl == false then
        self.load_next_lvl = true
        GAME:load_level(GAME.level+1, self.next_map_x)
    end
end

function St_GoNextLvl:on_exit(e)
    e.c_b.filter=nil
    e.c_move_hrz:on()
    e.c_gravity:on()
end