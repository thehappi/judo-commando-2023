--================================#
-- = GROUND STATE
--=

St_MkGround = Class('St_MkGround', St_EnGround)

function St_MkGround:__construct(e)
    St_EnGround.__construct(self, e)
    --=
end

function St_MkGround:on_enter(e, c_b)
    e:on('c_move_hrz')
    e:on('c_anim_dir')
    e:off('c_gravity')

    e.is_hittable_by_thrown = true
    c_b.is_platf_enabled = true

    e.c_b.vy = 0
    e.c_move_hrz:preset(Preset.C_Move_Hrz.St_MkGround)

    e.c_b:set_h(Tl.Dim * 0.8)
end

function St_MkGround:on_update(e, c_b, c_pad)

    if not c_b.is_on_ground then
       local st_enFall = St_EnFall(e, St_MkGround)
       return st_enFall
    end

    if c_pad:is_pressed('claw') then
        return St_MkClaw(e)
    end

    if c_pad:is_pressed('grab_hero') then
        return St_MkGrabHero(e)
    end
end

function St_MkGround:on_exit(e)
    e:off('c_move_hrz')
    e:off('c_gravity')
end

--================================#
-- = MELEE ATK STATE
--=

St_MkClaw = Class('St_MkClaw', StateComp)

function St_MkClaw:__construct(e)
    StateComp.__construct(self, e)
    --=
end

function St_MkClaw:on_enter(e, c_b)
    e:on('c_anim_dir')
    e:off('c_gravity')
    e.c_b.vy = 0

    e.c_anim:set('claw')
    e.c_anim:play()
end

function St_MkClaw:on_update(e, c_b, c_pad)
    if e.c_anim.is_over then
        if c_b.is_on_ground then
            return St_MkGround(e)
        else
            return St_EnFall(e)
        end
    end

    if not self.trigger then
        local dir=e.c_anim.dir
        local x, w = 0, Tl.Dim * 1.2
        local y, h = c_b.y, c_b.h

        if dir == 1 then
            x = c_b:mid_x()
        else
            x = c_b:mid_x() - w
        end

        local _, len = GAME.bump_world:queryRect(x, y, w, h, function(e) 
            return Xtype.is(e, E_Hero) and e.is_hittable
        end)

        if len > 0 then
            local pow_x = dir * Tl.Dim * 2
            local pow_y = -160

            GAME.e_hero.c_state_machine:set(
                St_HeroIsHit(GAME.e_hero, pow_x, pow_y)
            )
            self.trigger = true
        end
    end
end

function St_MkClaw:on_exit(e)
    e:off('c_anim_dir')
    e:on('c_gravity')
end

--================================#
-- = GRAB ATK STATE
--=

St_MkGrabHero = Class('St_MkGrabHero', StateComp)

function St_MkGrabHero:__construct(e)
    StateComp.__construct(self, e)
    --=
    self.is_air = false
    GAME.e_hero.c_state_machine:force_set(nil)
    GAME.e_hero.c_anim:off()
end

function St_MkGrabHero:on_enter(e, c_b)
    local e_hero = GAME.e_hero
    e:off('c_move_hrz')

    e.c_b:set_mid_x(e_hero.c_b:mid_x())

    self.is_air = not e.c_b.is_on_ground and not e.c_b.has_hit_ground

    if self.is_air then
        e.c_anim:set('grab_hero_air')
    end
    e_hero.c_state_machine:set(nil)
    e_hero.c_anim:off()
    e_hero.is_monkey_grabbed = true
end

function St_MkGrabHero:on_update(e, c_b)
    local shake_time = 0.5
    local shake_pow = 10

    -- = pick a lethal-attack anim at random
    if (e.c_b.is_on_ground or e.c_b.has_hit_ground) and not self.trigger then
        self.trigger=true
        e.c_anim:set('grab_hero_ground' .. math.random(1, 3))
    end
    -- = lethal-attack 1
    if e.c_anim:is('grab_hero_ground1') then
        if e.c_anim.enter_frame and e.c_anim:get_frame() == 1 then
            GAME.cam:shake(shake_time, shake_pow)
            GAME.e_hero.c_health:get_hit(10)
        end

        if e.c_anim.is_over then
            Timer.after(shake_time, function()  
                self.is_game_over = true
            end)
        end
    end
    -- = lethal-attack 2
    if e.c_anim:is('grab_hero_ground2') then
        if e.c_anim.enter_frame then
            local frame = e.c_anim:get_frame()

            if frame == 3 then
                e.c_anim:pause()
                Timer.after(0.4, function()  
                    e.c_anim:play()
                end)
            elseif frame == 7 then
                e.c_anim:pause()
                Timer.after(0.6, function()  
                    e.c_anim:play()
                end)
            elseif e.c_anim:get_frame() == 8 and e.c_anim.enter_frame then
                GAME.cam:shake(shake_time, shake_pow)
                GAME.e_hero.c_health:get_hit(10)
                
                Timer.after(shake_time, function()  
                    self.is_game_over = true
                end)
            end
        end
    end
    -- = lethal-attack 3
    if e.c_anim:is('grab_hero_ground3') then
        if e.c_anim.enter_frame then
            local frame = e.c_anim:get_frame()

            if frame == 3 then
                e.c_anim:pause()
                Timer.after(1, function()  
                    e.c_anim:play()
                end)
            elseif frame == 5 then
                GAME.cam:shake(shake_time, shake_pow)
                GAME.e_hero.c_health:get_hit(10)
            end
        end
        if e.c_anim.is_over then
            Timer.after(shake_time, function()  
                self.is_game_over = true
            end)
        end
    end
end
