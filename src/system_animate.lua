local Tiny = Tiny or require 'lib.tiny'

S_Animate=Tiny.sortedProcessingSystem()
S_Animate.active=false;

function S_Animate:filter(e)
    return e:has_active('c_b','c_anim')
end

function S_Animate:compare(e1, e2)
    if Xtype.is(e1, E_Hero) then
        return false
    elseif Xtype.is(e2, E_Hero) then
        return true
    -- elseif Xtype.is(e2, E_Enemy) then
    --     return true
        
    else
        return e1 == e2
    end
end

function S_Animate:process(e, dt)
    local c_b=e.c_b
    local c_anim=e.c_anim
    local props=c_anim.props
    local duration=0

    if c_anim.is_blinking then
        c_anim.blink_timer = c_anim.blink_timer + dt
        if c_anim.blink_timer > c_anim.blink_interval then
            c_anim.blink_timer = 0
            c_anim.blink_visible = not c_anim.blink_visible
        end
    end

    if not props then return end

    duration=props.duration
    if not c_anim.is_paused then

        c_anim.timer=c_anim.timer+dt
        if c_anim.timer > duration then
            if props.__loop then
                c_anim.timer=c_anim.timer-duration
            else
                c_anim.is_over=true
                c_anim.timer=duration
            end
        end
    end

    local frame_i = math.ceil(c_anim.timer / (duration / #props.frames))
   
    if c_anim.timer == 0 then
        frame_i=1
    end

    if frame_i ~= c_anim.frame_i then
        c_anim.enter_frame = true
    else
        c_anim.enter_frame = false
    end
    c_anim.frame_i = frame_i
    if not c_anim.is_blinking or c_anim.blink_visible then
        local cur_frame=props.frames[frame_i];
        local ox = c_anim.ox
        local oy = c_anim.oy
        local x = nil
        local y = nil

        if ox > 1 or ox < -1 then
            x = c_b.x+(c_b.w*0.5 + c_anim.dir * ox)
        else
            x = c_b.x+c_b.w*0.5
        end

        if oy > 1 or oy < 1 then
            y = c_b.y+(c_b.h - oy)
        else
            y = c_b.y+c_b.h*oy
        end

        local sx = c_anim.dir
        local sy = 1
        if c_anim.scale_x then
            sx = sx * c_anim.scale_x
        end
        if c_anim.scale_y then
            sy = sy * c_anim.scale_y
        end

        if cur_frame then
            -- love.graphics.setColor(unpack(e.c_b.color))
            if e.c_anim.color then
                love.graphics.setColor(e.c_anim.color)
            else
                love.graphics.setColor(GAME and GAME.draw_color.anims or {1,1,1,1})
            end
            if c_anim.shader then
                love.graphics.setShader(c_anim.shader)
            end
            
            love.graphics.draw(props.spritesheet, cur_frame.quad, (x), (y), c_anim.r, sx, sy, cur_frame.w * cur_frame.ox, cur_frame.h)
            -- love.graphics.draw(props.spritesheet, cur_frame.quad, (x), (y), c_anim.r, sx, 1, ox, cur_frame.h)
            love.graphics.setColor(1,1,1)
            love.graphics.setShader()
        end
    end
end

--===========================#
--

S_Animate_Hero_Atlas=Tiny.processingSystem()
S_Animate_Hero_Atlas.active=false;

function S_Animate_Hero_Atlas:filter(e)
    return e:has_active('c_b', 'c_anim', 'c_state_machine') and e.c_anim.atlas == Atlas.Hero
end

function S_Animate_Hero_Atlas:process(e, dt)
    local c_b = e.c_b
    local c_anim = e.c_anim
    local c_anim_dir = e.c_anim_dir
    local c_sm = e.c_state_machine

    local st = c_sm:get()
    local on_enter = st.is_on_enter
    local on_update = st.is_on_update
    local frame = c_anim.frame_i
    local on_enter_frame = c_anim.enter_frame
    -- print(frame)
    if c_anim_dir and e:has_active('c_anim_dir') then
        if c_b.vx > 0 then -- pourri
            c_anim.dir = 1
        elseif c_b.vx < 0 then
            c_anim.dir = -1
        end
    end

    if c_sm:is(St_ClimbCorner) then
        local normal_x = st.normal_x

        if on_enter then
             if normal_x == -1 then
                -- c_anim:set('corner_climb', 1.05, 0.95)--1.05, 1.15)
                -- c_anim:set('corner_climb')--1.05, 1.15)
                -- print('ici')
            else
                -- c_anim:set('corner_climb')--1.05, 1.15)
                -- print('la')
                -- c_anim:set('corner_climb', 0.05, 0.95)---0.05, 1.15)
            end
        end

    elseif c_sm:is(St_ClimbPlatf) then

        if on_enter then
            c_anim:set('platf_climb')
        end

    elseif c_sm:is(St_OnGuard1) then

        if on_enter then
            c_anim:set('combo1_idle')
        end
    
    elseif c_sm:is(St_Ladder) then
        
        if on_enter then
            c_anim:set('ladder')
        end
        
        if on_update then
            if c_b.vy ~= 0 then c_anim:play()
            else c_anim:pause() end
        end

    elseif c_sm:is(St_HangToPlatf) then
        if on_enter then
            c_anim:set('platf_move')
        end
        if on_update then
            if c_b.vx ~= 0 then
                c_anim:play()
            else
                c_anim:pause()
            end
        end
    elseif c_sm:is(St_HeroGround) then
        if c_b.vx > 0 then
            c_anim:set('run')
        elseif c_b.vx < 0 then
            c_anim:set('run')
        else
            c_anim:set('idle')
        end

    elseif c_sm:is(St_GoNextLvl) then
        if on_enter then
            c_anim:set('jump')
            c_anim:set_frame(6)
            c_anim:pause()
        end

        if on_update then
            -- print(c_b.vy)
            if e.c_gravity.max and c_b.vy >= e.c_gravity.max then
                c_anim:set_frame(8)
            elseif c_b.vy > 100 then
                c_anim:set_frame(7)
            elseif c_b.vy > 50 then
                c_anim:set_frame(6)
            elseif c_b.vy > -50 then
                c_anim:set_frame(5)
            elseif c_b.vy > -80 then
                c_anim:set_frame(4)
            elseif c_b.vy > -120 then
                c_anim:set_frame(3)
            elseif c_b.vy > -150 then
                c_anim:set_frame(2)
            end
        end

    elseif c_sm:is(St_HeroFall) then
        if on_enter then
            c_anim:set('jump')
            c_anim:pause()
        end

        if on_update then
            -- print(c_b.vy)
            if e.c_gravity.max and c_b.vy >= e.c_gravity.max then
                c_anim:set_frame(8)
            elseif c_b.vy > 100 then
                c_anim:set_frame(7)
            elseif c_b.vy > 50 then
                c_anim:set_frame(6)
            elseif c_b.vy > -50 then
                c_anim:set_frame(5)
            elseif c_b.vy > -80 then
                c_anim:set_frame(4)
            elseif c_b.vy > -120 then
                c_anim:set_frame(3)
            elseif c_b.vy > -150 then
                c_anim:set_frame(2)
            end
        end

    elseif c_sm:is(St_Duck) then
        if on_enter then
            c_anim:set('duck')
            if st.skip_enter_anim then
                c_anim:set_frame(#c_anim.props.frames)
            end
        end

    elseif c_sm:is(St_OnGuard1Front) then

        if on_enter then
            c_anim:set('combo1_forward')

        elseif on_update and on_enter_frame then
            local dir = c_anim.dir

            if frame == 1 then
                c_b:move_x(2 * dir)

            elseif frame == 2 then
                c_b:move_x(2 * dir)
            
            elseif frame == 3 then
                c_b:move_x(2 * dir)

                c_anim:pause()
                Timer.after(0.150, function() c_anim:play() end)
            end
        end

    elseif c_sm:is(St_OnGuard1Back) then
        
        if on_enter then
            c_anim:set('combo1_back')
        
        elseif on_update and on_enter_frame then
            if frame == 2 then
                c_anim.ox = 4
                st.e_target.c_anim:set('gethit')
                st.e_target.c_anim:set_frame(1)
                st.e_target.c_anim:pause()

            elseif frame == 3 then
                st.e_target.c_anim:play()
            
            elseif frame == 4 then
                c_anim:pause()
                Timer.after(0.2, function() c_anim:play() end)
            end
        end
    
    elseif c_sm:is(St_OnGuard1Up) then
        if on_enter then
            e.c_anim:set('combo1_u')
        elseif on_update and on_enter_frame then
            if frame == 2 then
                c_anim:pause()
                Timer.after(0.350, function() c_anim:play() end)
            end
        end

    elseif c_sm:is(St_HeroGetUp) then
        if on_enter then
            e.c_anim:set('getup')
        end
    elseif c_sm:is(St_OnGuard2Combo) then
        local e_en = st.e_target

        if on_enter then
            e.c_anim:set('combo2_throw_forward')
        elseif on_update and on_enter_frame then
            if frame == 1 then
                e_en.c_anim.oy = -10
            elseif frame == 2 then
                e_en.c_anim.oy = -12
            elseif frame == 3 then
                e.c_anim.ox = -2
                e_en.c_anim.oy = 0
            end
        end

    elseif c_sm:is(St_OnGuard3Up) then
        local e_en = st.e_target

        if on_enter then
            e.c_anim:set('combo3_u')
            e_en.c_anim:set('combo3_ued')
            e_en.c_anim:pause()
        elseif on_update and on_enter_frame then    
            if frame == 2 then
                e_en.c_anim:set_frame(2)
                e_en.c_anim.ox = 16
            elseif frame == 4 then
                e.c_anim:pause()
                Timer.after(0.150, function() e.c_anim:play() end)
            end
        end

    elseif c_sm:is(St_IdleOverEnemyThrow) then
        local e_en = st.e_en

        if on_enter then
            e.c_anim:set('onen_d')
        elseif on_update and on_enter_frame then
            if frame == 1 then
                e.c_anim.ox = 16
            elseif frame == 2 then
                e_en.c_anim:set('combo1_idle')
            elseif frame == 11 then
                e.c_anim:pause()
                Timer.after(0.05, function() e.c_anim:play() end)
            end
        end
    end
end

--===========================#
--

S_Animate_Enemy_Atlas=Tiny.processingSystem()
S_Animate_Enemy_Atlas.active=false;

function S_Animate_Enemy_Atlas:filter(e)
    -- print(e, e:has_active('c_b', 'c_anim', 'c_state_machine'), Xtype.is(e, E_Enemy))
    return e:has_active('c_b', 'c_anim', 'c_state_machine') and Xtype.is(e, E_Enemy)
end

function S_Animate_Enemy_Atlas:process(e, dt)
    local c_b = e.c_b
    local c_anim = e.c_anim
    local c_anim_dir = e.c_anim_dir
    local c_sm = e.c_state_machine

    local state = c_sm:get()
    if not state then 
        return 
    end
    
    local on_enter = state.is_on_enter
    local on_update = state.is_on_update
    local on_enter_frame = c_anim.enter_frame
    local frame = c_anim:get_frame()

    if c_anim_dir and e:has_active('c_anim_dir') then
        if c_b.vx > 0 then -- pourri
            c_anim.dir = 1
        elseif c_b.vx < 0 then
            c_anim.dir = -1
        end
    end

    if c_sm:is(St_Ladder) then
        
        if state.on_enter then
            c_anim:set('ladder')
        end
        
        if state.is_on_update then
            if c_b.vy ~= 0 then c_anim:play()
            else c_anim:pause() end
        end

    elseif c_sm:is(St_EnGround) or c_sm:is(St_MkGround) then
        if c_b.vx > 0 then
            c_anim:set('walk')
        elseif c_b.vx < 0 then
            c_anim:set('walk')
        else
            -- = bug
            c_anim:set('idle')
        end

        if c_anim_dir then
            if c_b.vx > 0 then -- pourri
                c_anim.dir = 1
            elseif c_b.vx < 0 then
                c_anim.dir = -1
            end
        end

    elseif c_sm:is(St_EnFall) or c_sm:is(St_Jump) or c_sm:is(St_NinjaJump) then
        if c_anim_dir then
            if c_b.vx > 0 then -- pourri
                c_anim.dir = 1
            elseif c_b.vx < 0 then
                c_anim.dir = -1
            end
        end

        if state.is_on_enter then
            if e.type == E_Enemy.Type.Ninja then
                if c_sm:is(St_EnFall) then
                    c_anim:set('ninja_fall')
                end

                if c_sm:is(St_Jump) or c_sm:is(St_NinjaJump) then
                    c_anim:set('ninja_jump')
                end
            elseif e.type == E_Enemy.Type.Monkey then
                c_anim:set('monkey_jump')
            else
                c_anim:set('jump')
                c_anim:pause()
            end
        end

        if state.is_on_update then
            if c_anim:is('jump') then
                if e.c_gravity.max and c_b.vy >= e.c_gravity.max then
                    c_anim:set_frame(7)
                elseif c_b.vy > 100 then
                    c_anim:set_frame(6)
                elseif c_b.vy > 50 then
                    c_anim:set_frame(5)
                elseif c_b.vy > -50 then
                    c_anim:set_frame(4)
                elseif c_b.vy > -80 then
                    c_anim:set_frame(3)
                elseif c_b.vy > -120 then
                    c_anim:set_frame(2)
                elseif c_b.vy > -150 then
                    c_anim:set_frame(1)
                end
            end
        end

    elseif c_sm:is(St_EnDuck) then
        if state.is_on_enter then
            c_anim:set('duck')
        end
        
    elseif c_sm:is(St_EnOnGuard1) then

        if state.is_on_enter or state.is_on_update then
            c_anim:set('combo1_idle')
        end
    elseif c_sm:is(St_Punch) then
        if on_enter then
            c_anim:set('punch')
            c_anim:pause()
            Timer.after(0.45, function()
                c_anim:set_frame(2)
                c_anim:play()
            end)
        elseif on_update and on_enter_frame then
            if frame == 2 then
                c_anim.ox = 6
            elseif frame == 3 then
                c_anim.ox = 8
            elseif frame == 4 then
                c_anim.ox = 6
            end
        end
    end
    -- print (c_anim.cur_key,  c_b.vx)
end

--===========================#
--

S_Animate_Fx=Tiny.processingSystem()
S_Animate_Fx.active=false;

function S_Animate_Fx:filter(e)
    return e:has_active('c_b', 'c_anim') and Xtype.is(e, E_Fx)
end

function S_Animate_Fx:process(e, dt)
    local c_anim = e.c_anim

    local on_enter_frame = c_anim.enter_frame
    local frame_i = c_anim:get_frame()

    if Xtype.is(e, E_FxRocketAiming) then
        if on_enter_frame then
            if frame_i == 5 then
                c_anim:pause()
                c_anim:off()
                Timer.after(0.15, function() 
                    c_anim:on()
                    c_anim:play()
                end)
             end
        end
    end
end