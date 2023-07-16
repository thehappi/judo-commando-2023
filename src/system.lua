local Tiny = Tiny or require 'lib.tiny'
local GameSignal = GameSignal or require 'gamesignal'


--====#
S_DrawBodyOutline=Tiny.processingSystem()
S_DrawBodyOutline.active=false;
--=======================================#

function S_DrawBodyOutline:filter(e)
    return e:has_active('c_b') and e.c_b.dbg_outline == true
end

function S_DrawBodyOutline:process(e, dt)
    local c_b = e.c_b-----
    local color = c_b.dbg_outline_color or {0, 1, 0}
    local map = GAME.map

    -- = body outline
    if c_b.dbg_outline_color then
        love.graphics.setColor(color[1], color[2], color[3], 1)
    else
        love.graphics.setColor(GAME.draw_color.debug or {0, 1, 0})
    end
    love.graphics.setLineWidth(1)
    love.graphics.rectangle('line', c_b.x, map.y + map.h + c_b.y, c_b.w, c_b.h)
    -- body origin
    if c_b.draw_origin then
        love.graphics.setColor(1,1,1)
        -- love.graphics.line(c_b.x, c_b.y, c_b.x + c_b.hitbox_origin.x, c_b.y + c_b.hitbox_origin.y)
        -- love.graphics.setColor(unpack(color))
        -- love.graphics.line(c_b.x, c_b.y-3, c_b.x, c_b.y+3)
        -- love.graphics.line(c_b.x-3, c_b.y, c_b.x+3, c_b.y)
        -- love.graphics.setColor(1,1,1)
        -- love.graphics.line(c_b.x, c_b.y-2, c_b.x, c_b.y+2)
        -- love.graphics.line(c_b.x-2, c_b.y, c_b.x+2, c_b.y)
    end
    love.graphics.setColor(1,1,1)
end


--====#
S_PadListener=Tiny.processingSystem()
S_PadListener.active=false;
--=======================================#

function S_PadListener:filter(e)
    return e:has_active('c_pad')
end

function S_PadListener:process(e)
    local c_pad = e.c_pad

    c_pad:clear()

    if c_pad.listen_to_keyboard then
        -- local mobile = false
        -- if love.system.getOS() == 'iOS' or love.system.getOS() == 'Android' then
        --     mobile = true
        -- end
        for game_keyname, key in pairs(c_pad.__keys) do
            local oldk = c_pad.__oldkeys[game_keyname]

            key.is_pressed = (not IS_MOBILE and love.keyboard.isDown(key.love_keyname)) 
                or (IS_MOBILE and lovepad:isDown(key.love_keyname))

            if key.is_pressed then
                key.time_pressed = key.time_pressed + love.timer.getDelta()
            end

            key.is_released =
                not key.is_pressed and oldk and oldk.is_pressed

            key.is_pressed_once = 
                key.is_pressed and oldk and not oldk.is_pressed

            -- if key.is_pressed_once then
            --     key.pressed_at = love.timer.getTime()
            -- end

            -- if key.is_released then
            --     key.released_at = love.timer.getTime()
            -- end
        end
    end
end

--====#
S_OldPadUpdater=Tiny.processingSystem()
S_OldPadUpdater.active=false;
--=======================================#

function S_OldPadUpdater:filter(e)
    return e:has_active('c_pad')
end

function S_OldPadUpdater:process(e)
    local c_pad = e.c_pad

    for game_keyname, key in pairs(c_pad.__keys) do
        local oldk = c_pad.__oldkeys[game_keyname]

        if key.is_released then
            key.time_pressed = 0
        end

        oldk.is_pressed = key.is_pressed
    end
end

--====#
S_ResolveEvents=Tiny.processingSystem()
S_ResolveEvents.active=false;
--=======================================#

function S_ResolveEvents:onAddToWorld(e)
    -- Signal.register('has_hit_ground', function(e)
        -- print('gooooooooooooooood', e)
    -- end)
end

function S_ResolveEvents:filter(e)
    return e:has_active('c_event_listener')
end

function S_ResolveEvents:process(e)
    local c_ev_lsn = e.c_event_listener

    self.__signals_emitted = {}
end


--====#
S_ProjectileSolver=Tiny.processingSystem()
S_ProjectileSolver.active=true;
--=======================================#

function S_ProjectileSolver:filter(e)
    return e:has_active('c_projectile', 'c_anim')
end

function S_ProjectileSolver:isEnemyValidHitTarget(e_projectile, e_target)
    return Xtype.is(e_target, E_Enemy)
        and e_target:has_active('c_state_machine')
        and e_projectile.c_projectile.e_owner ~= e_target
        and ( e_target.is_hittable or e_target.c_state_machine:is(St_EnIsHit) )
end

function S_ProjectileSolver:isHeroValidHitTarget(e_projectile, e_target)
    return e_target.is_hittable 
        and e_target:has_active('c_state_machine')
end

function S_ProjectileSolver:process(e)
    local c_b = e.c_b
    local c_bullet = e.c_projectile

    local dt = love.timer.getDelta()
    local dx = c_bullet.dir_x
    local dy = c_bullet.dir_y

    local hit_coll = nil -- bump coll
    local hit_pow_x = c_bullet.pow_x * dx
    local hit_pow_y = c_bullet.pow_y

    c_b.vx = c_bullet.speed * dx
    c_b.vy = c_bullet.speed * dy

    c_bullet.dist_x = c_bullet.dist_x + (math.abs(c_b.vx) * dt)

    -- = check for hero
    for _, coll in ipairs(c_b:colls_with('E_Hero')) do
        local e_tgt = coll.other
        if self:isHeroValidHitTarget(e, e_tgt) then
            -- e_tgt.c_state_machine:set(St_HeroIsHit(e_tgt, 128 * dx, -128))
            if Xtype.is(e, E_Shuriken) then
                e_tgt.c_state_machine:force_set(St_HeroIsHit(e_tgt, 170 * e.c_anim.dir, -118))
                e_tgt.c_health:get_hit(2)

            elseif Xtype.is(e, E_Bullet) then
                e_tgt.c_state_machine:force_set(St_HeroIsHit(e_tgt, 170 * dx, -118))
                -- e_tgt.c_state_machine:set(St_HeroIsHit(e_tgt, 170 * dx, -118))
                e_tgt.c_health:get_hit(2)
            elseif Xtype.is(e, E_Rocket) then
                e_tgt.c_state_machine:set(St_HeroIsHit(e_tgt, 144 * dx, -280))
                e_tgt.c_health:get_hit(5)
            end
            hit_coll = coll
        end
    end
    -- = check for enemy
    for _, coll in ipairs(c_b.colls) do
        if hit_coll then break end

        local e_tgt = coll.other
        local c_sm = e_tgt.c_state_machine

        if self:isEnemyValidHitTarget(e, e_tgt) then
            if not c_sm:is(St_EnIsHit) then
                c_sm:force_set(St_EnIsHit(e_tgt, hit_pow_x, hit_pow_y, false))
            end
            hit_coll = coll
            --=
            e_tgt.c_anim.shader = SHADER_IS_HIT
            Timer.after(0.1, function() e_tgt.c_anim.shader = nil end)
        end
    end
    -- = check for wall or platform 
    for _, coll in ipairs(c_b.__colls_with_tile) do
        local e_tgt = coll.other
        if e_tgt then
            if e_tgt.c_tile:has_prop(Tl.Prop.Wall) then
                hit_coll = coll
            elseif e_tgt.c_tile:has_prop(Tl.Prop.Platform) and coll.normal.y == -1 then
                hit_coll = coll
            end
        end
    end
    -- = on hit
    if hit_coll then 
        -- = spawn fx
        local spawn_x = hit_coll.touch.x + (hit_coll.normal.x == -1 and e.c_b.w or 0)
        local spawn_y = c_b:mid_y()
        
        if c_bullet.spawn_e then
            GAME:add_e( c_bullet.spawn_e(spawn_x, spawn_y, e.c_anim.dir) )
        end
        if Xtype.is(e, E_Rocket) then
            -- local e_target = hit_coll.other
            local impact_x = nil

            if hit_coll.normal.x == -1 then
                impact_x = e.c_b:left()
            else
                impact_x = e.c_b:right()
            end

            GAME:rocketImpact(impact_x, c_b:mid_y())
        end
        -- = remove projectile
        GAME:del_e(e)
        c_bullet:off()
    end
end


--====#
S_BombSolver=Tiny.processingSystem()
S_BombSolver.active=false;
--=======================================#

function S_BombSolver:filter(e)
    return e:has_active('c_mine', 'c_b')
end

-- = check if hero collides with bomb
function S_BombSolver:checkHeroColl(e)
    local c_b = e.c_b

    for _, coll in ipairs(c_b:colls_with('E_Hero')) do
        local c_sm = coll.other.c_state_machine
        if not c_sm:is(St_GoNextLvl) then
            return coll.other
        end
    end
    return nil
end

-- = check if an enemy collides with bomb
function S_BombSolver:checkEnemyColl(e)
    local c_b = e.c_b
    for _, coll in ipairs(c_b.colls) do
        if coll.other:has_active('c_state_machine') then
            local c_sm = coll.other.c_state_machine
            if
                c_sm and
                c_sm:is(St_EnIsHit) or
                c_sm:is(St_EnHitGround) or
                c_sm:is(St_EnDead) or
                c_sm:is(St_EnMeteorCombo)
            then
                return coll.other
            end 
        end
    end
    return nil
end

function S_BombSolver:process(e)
    local c_b = e.c_b
    local e_target = nil

    -- = bomb disapear after some time
    e.c_mine.timer = e.c_mine.timer + love.timer.getDelta()
    if e.c_mine.timer > e.c_mine.remove_at then
        GAME:del_e(e)
        return
    end
    -- = if valid target collides
    e_target = self:checkEnemyColl(e)
    if not e_target then
        e_target = self:checkHeroColl(e)
    end
    -- = ** explode **
    if e_target then
        e:off('c_mine')
        GAME:add_e(E_Explosion(c_b:mid_x(), c_b:mid_y()))
        GAME:bombImpact(c_b:mid_x(), c_b:mid_y()+2)
        GAME:del_e(e)
    end
end


--====#
S_DelOnAnimOver=Tiny.processingSystem()
S_DelOnAnimOver.active=true;
--=======================================#

function S_DelOnAnimOver:filter(e)
    return e:has_active('c_del_on_anim_over', 'c_anim')
end

function S_DelOnAnimOver:process(e)
    if e.c_anim.is_over then
        GAME:del_e(e)
    end
end

--====#
S_FxTrailGenerator=Tiny.processingSystem()
S_FxTrailGenerator.active=true;
--=======================================#

function S_FxTrailGenerator:filter(e)
    return e:has_active('c_fx_trail', 'c_b')
end

function S_FxTrailGenerator:process(e)
    local c = e.c_fx_trail
    local c_b = e.c_b

    c.timer = c.timer + love.timer.getDelta()
    if c.timer > c.time_interval then
        c.timer = 0
        GAME.add_e( E_FxRocketSmoke(c.dir_x == 1 and c_b:left() or c_b:right(), c_b:mid_y() + c.dir_y * 4))
        c.dir_y = -c.dir_y
    end
end


--====#
S_BlinkUpdate=Tiny.processingSystem()
S_BlinkUpdate.active=false;
--=======================================#

function S_BlinkUpdate:filter(e)
    return e.c_blink and  e.c_blink.active
end

function S_BlinkUpdate:process(e, dt)
    local c_blink = e.c_blink
    local t = c_blink.timer

    t = t + love.timer.getDelta()

    if t > c_blink.hertz * 0.5 then
        t = 0
        c_blink.is_switch_on = not c_blink.is_switch_on
    end
    c_blink.timer = t
end


--====#
S_UpdateScoreText=Tiny.processingSystem()
S_UpdateScoreText.active=false;
--=======================================#

function S_UpdateScoreText:filter(e)
    return e:has_active('c_text', 'c_b')
end

function S_UpdateScoreText:process(e, dt)
    local c_text=e.c_text
    local t = c_text.timer

    t = t + love.timer.getDelta()

    -- if Xtype.is(e.e_source, E_Enemy) then
        -- if e.e_source and e.e_source.active == false then
        --     GAME:del_e(e)
        -- end
    
        if t > c_text.blink_at and not e:has_active('c_blink') then
            e.c_blink:on()
            GAME.tiny_world:addEntity(e)
            t = 0
        end

        if t > c_text.erase_at and e:has_active('c_blink') and e.c_blink.is_switch_on == false then
            GAME:del_e(e)
        end
    -- end

    c_text.timer = t
end


--====#
S_DrawScoreText=Tiny.processingSystem()
S_DrawScoreText.active=false;
--=======================================#

function S_DrawScoreText:filter(e)
    return e:has_active('c_text')
end

function S_DrawScoreText:process(e, dt)
    if Xtype.is(e.e_source, E_Enemy) then        
        if e.c_text.timer < e.c_text.blink_at or (e.e_source.c_anim.blink_visible) then
            love.graphics.draw(e.c_text.o_text, e.c_b.x, e.c_b.y)
        end
    elseif not e.c_blink or e.c_blink.is_switch_on then
        love.graphics.draw(e.c_text.o_text, e.c_b.x, e.c_b.y)
    end
end

--====#
S_UpdateJewel=Tiny.processingSystem()
S_UpdateJewel.active=true;
--=======================================#

function S_UpdateJewel:filter(e)
    return e:has_active('c_jewel')
end

function S_UpdateJewel:process(e, dt)
    local c_jewel = e.c_jewel
    local c_pickable = e.c_pickable
    local c_b = e.c_b

    local t = c_jewel.timer
    local t2 = c_jewel.timer2
    
    t = t + love.timer.getDelta()
    t2 = t2 + love.timer.getDelta()

    if e.c_jewel.loop_n == 0 then
        if t > 0.75 then
            e.c_anim:play()
        end
    end

    if e.c_anim.is_blinking == false then

        if e.c_anim.is_paused and e.c_jewel.loop_n > 0 then
            if t2 > 1.5 then
                e.c_anim:play()
            end
        end

        if not e.c_anim.is_paused then
            if e.c_anim.is_over then
                e.c_jewel.loop_n = e.c_jewel.loop_n + 1
                e.c_anim:reset()
                e.c_anim:set_origin(nil, 2)

                t2 = 0

                if e.c_jewel.loop_n == 3 then
                    e.c_jewel.loop_n = 1
                end

                if e.c_jewel.loop_n == 1 then
                    e.c_anim:pause()
                end
            end
        end

        if e.c_anim.is_paused and t2 > 1.5 then
            e.c_anim:play()
            e.c_jewel.loop_n = e.c_jewel.loop_n + 1
        end

        if not e.c_anim.is_paused and e.c_anim.is_over then
            if e.c_jewel.loop_n % 2 ~= 0 then
                e.c_anim:pause()
            end
            t2 = 0
        end
    end

    if t > c_jewel.blink_at and not e.c_anim.is_blinking then
        e.c_anim:blink(0.1)
    end

    if t > c_jewel.erase_at and not e.c_anim.blink_visible then
        GAME:del_e(e)
    end

    if c_pickable.is_picked_up then
        -- GAME.score = GAME.score + GAME.Score_Table.Jewel
        GAME.game_ui.jewel_ui:onJewelGathered(c_jewel.color)
        GameSignal:jewelCollected(e)
        -- GAME:add_e(E_ScoreTxt(c_b:mid_x(), c_b:mid_y(), GAME.Score_Table.Jewel))
        GAME:del_e(e)
    end

    c_jewel.timer = t
    c_jewel.timer2 = t2
end


--====#
S_UpdateLifeUp=Tiny.processingSystem()
S_UpdateLifeUp.active=true;
--=======================================#

function S_UpdateLifeUp:filter(e)
    return e:has_active('c_life_up')
end

function S_UpdateLifeUp:process(e, dt)
    local c_life_up = e.c_life_up
    local c_pickable = e.c_pickable
    local c_b = e.c_b

    local t = c_life_up.timer
    local t2 = c_life_up.timer2
    
    t = t + love.timer.getDelta()
    t2 = t2 + love.timer.getDelta()

    if e.c_anim.is_blinking == false then

        if e.c_anim.is_paused and t2 > 2.5 then
            e.c_anim:play()
        end

        if not e.c_anim.is_paused and e.c_anim.is_over then
            e.c_anim:reset()
            e.c_anim:pause()
            t2 = 0
        end
    end

    if t > c_life_up.blink_at and not e.c_anim.is_blinking then
        e.c_anim:blink(0.1)
    end

    if t > c_life_up.erase_at and not e.c_anim.blink_visible then
        GAME:del_e(e)
    end

    if c_pickable.is_picked_up then
        local e_hero = GAME.e_hero

        if e.c_life_up.size == E_LifeUp.Size.Sm then
            e_hero.c_health:heal(1)
        elseif e.c_life_up.size == E_LifeUp.Size.Md then
            e_hero.c_health:heal(3)
        end
        GAME:del_e(e)
    end

    c_life_up.timer = t
    c_life_up.timer2 = t2
end


--====#
S_Pickable=Tiny.processingSystem()
S_Pickable.active=true;
--=======================================#

function S_Pickable:filter(e)
    return e:has_active('c_b', 'c_pickable')
end

function S_Pickable:process(e, dt)
    local c_b = e.c_b
    local c_pickable = e.c_pickable

    if c_b.__colls_with['E_Hero'] and not c_pickable.is_picked_up then
        -- GAME:add_e(E_FxItemPickedUp(c_b:mid_x(), GAME.e_hero.c_b:bot()-Tl.Dim*0.5))
        local e_tl = GAME.map:tile_at(c_b:mid_x(), c_b:bot())

        GAME:add_e(E_FxItemPickedUp(c_b:mid_x(), e_tl.c_b:mid_y()))
        c_pickable.is_picked_up = true
    end
end


--====#
S_HandleDeadEnemies=Tiny.processingSystem()
S_HandleDeadEnemies.active=true;
--=======================================#

function S_HandleDeadEnemies:filter(e)
    return Xtype.is(e, E_Enemy) and e:has_active('c_health')
end

function S_HandleDeadEnemies:process(e, dt)
    local c_b = e.c_b

    if e.c_health.hp == 0 then
        e.is_pickable=false
        e.is_catchable=false
        e.is_hittable=false
        e.is_grabbable=false
        e.is_carrying_hero=false
        e.is_armlockable=false
        if  e.c_anim.is_blinking == false then
            -- local score = GAME.Score_Table[e.type]
            GameSignal:enemyKilled(e)
            -- GAME.score = GAME.score + score
            -- GAME:add_e( E_ScoreTxt(c_b:mid_x(), c_b:bot()-16, GAME.Score_Table[e.type], e) )
            e.c_anim:blink(0.08)
        end
    end
end

--====#
S_ClearOutbound=Tiny.processingSystem()
S_ClearOutbound.active=true;
--=======================================#

function S_ClearOutbound:filter(e)
    return e:has_active('c_b') and not e.c_b.is_static
end

function S_ClearOutbound:process(e, dt)
    local c_b = e.c_b
    local world = GAME.world

    if c_b.x < world.l or c_b.x > world.l+world.w or c_b.y < world.t or c_b.y > world.t+world.h then

        e.c_b.is_outbouds = true
        GAME:del_e(e)

        if e:has_active('c_health') then
            e.c_health.hp = 0
        end
        if e:has_active('c_anim') then
            e.c_anim:off()
        end
    end
end

--====#
S_DebrisColl=Tiny.processingSystem()
S_DebrisColl.active=true;
--=======================================#

function S_DebrisColl:filter(e)
    return e:has_active('c_b', 'c_debris')
end

function S_DebrisColl.filter_coll(e, o)
    local e_tile = o

    if Xtype.is(o, E_Tile) then
        local c_tile = o.c_tile

        if c_tile:has_prop(Tl.Prop.Empty) then
            return nil
        end

        -- if e.c_b.vy < 0 and c_tile:has_prop(Tl.Prop.Ground) then
        --     return 'bounce'                
        -- end

        if e.c_b.vy > 0 and c_tile:has_prop(Tl.Prop.Ground) then
            return 'slide'
        end

        if c_tile:has_prop(Tl.Prop.Wall) then
            return 'slide'
        end
    end
    return nil
end

function S_DebrisColl:process(e)
    local c_b = e.c_b
    local c_debris = e.c_debris
    local dt = love.timer.getDelta()

    local goal_x=c_b.x + c_b.vx * dt 
    local goal_y=c_b.y + c_b.vy * dt
    
    c_b.colls=colls
    c_b.__colls_with_tile = {}

    local goal_x, goal_y, colls, _ = GAME.bump_world:check(e, goal_x, goal_y, self.filter_coll)

    if not c_debris.has_hit_ground then
        for _, coll in ipairs(colls) do
            local o = coll.other
                -- = hit ground
            if c_b.vy > 0 and coll.normal.y == -1 and o.c_tile:has_prop(Tl.Prop.Ground) and c_b:bot() < o.c_b:top() then
                c_b.has_hit_ground = coll
                c_debris.has_hit_ground = coll
                c_b.vx = 0
            end
        end
    end
    e.c_b.x = goal_x
    e.c_b.y = goal_y

    GAME.bump_world:update(e, c_b.x, c_b.y, c_b.w, c_b.h)

    if c_debris.has_hit_ground then
        e.c_debris.timer = e.c_debris.timer + dt
        if e.c_debris.timer > e.c_debris.erase_at then
            GAME:del_e(e)
        end
    end
end

--====#
S_Melee_Range=Tiny.processingSystem()
S_Melee_Range.active=false;
--=======================================#

function S_Melee_Range:filter(e)
    return e:has_active('c_b') and 
        (e:has_active('c_punch') or e:has_active('c_katana'))
end

function S_Melee_Range:process(e, dt)
    local c_b = e.c_b
    local dist_x = math.abs(c_b:dist_x(GAME.e_hero.c_b))
    local dist_y = c_b:dist_y(GAME.e_hero.c_b)

    if e.c_punch then
        e.c_punch.is_hero_in_range = dist_x < e.c_punch.range and dist_y == 0
    end

    if e.c_katana then
        e.c_katana.is_hero_in_range = dist_x < e.c_katana.range and dist_y <= 0 and dist_y >= -40
    end
end

--====#
S_IsGuarding = Tiny.processingSystem()
S_IsGuarding.active = false
--=======================================#

function S_IsGuarding:filter(e)
    return e.c_guard and e:has_active('c_state_machine')
end

function S_IsGuarding:process(e, dt)
    local guard_states = {}

    e.is_guarding = false

    if Xtype.is(e, E_Hero) then
        guard_states = {
            St_OnGuard1,
            St_OnGuard2,
            St_OnGuard3,
            St_OnGuard1Up,
            St_OnGuard1Front,
            St_OnGuard1Back,
            St_OnGuard2Combo,
            St_OnGuard3Kick,
            St_OnGuard3Down,
            St_OnGuard3Up,
        }
    end

    if Xtype.is(e, E_Enemy) then
        guard_states = {St_EnOnGuard1, St_EnOnGuard2, St_EnOnGuard3}
    end

    for _, state in ipairs(guard_states) do
        if e.c_state_machine:is(state) then
            e.is_guarding = true
            break
        end
    end
end

--====# 
S_IsHittable = Tiny.processingSystem()
S_IsHittable.active = false
--=======================================#

function S_IsHittable:filter(e)
    return e.c_hittable and e:has_active('c_state_machine')
end

function S_IsHittable:process(e, dt)
    local states = {}

    e.is_hittable = false

    if Xtype.is(e, E_Hero) then
        if e.c_guard and e.is_guarding then
            e.is_hittable = true
        else
            states = {
                St_HeroGround,
                St_HeroFall,
                St_Duck,
                St_Ladder,
                St_IdleOverEnemyThrow,
                St_ClimbPlatf
            }
        end
    end

    if Xtype.is(e, E_Enemy) then
        if e.c_guard and e.is_guarding then
            e.is_hittable = true
        else
            states = {}
        end
    end

    for _, state in ipairs(states) do
        if e.c_state_machine:is(state) then
            e.is_hittable = true
            break
        end
    end
end
