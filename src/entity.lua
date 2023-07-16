local Game = Game or require 'game'
local C_Body = C_Body or require 'component_body'

Entity=Class('Entity')

local __set_comp=function(self, is_enabled, ...)
    local comps_attribute_as_string={...}
    for _, comp_name in ipairs(comps_attribute_as_string) do
        local comp=self[comp_name]
        if comp == nil then
            return
        end
        -- print(type(comp), comp_name, comp, is_enabled)
        if Xtype.is(comp, Comp) then
            if is_enabled then
                comp:on()
            else
                comp:off()
            end
        elseif type(comp)=='boolean' then
            self[comp_name]=is_enabled
        end
    end
end

function Entity:__construct(e)
    if (GAME) then
        GAME.tiny_world:addEntity(e)
    end
    e.active=true
end

function Entity:on(...)
    __set_comp(self, true, ...)
end

function Entity:off(...)
    __set_comp(self, false, ...)
end

function Entity:all_off()
    for k, v in pairs(self) do
        if Xtype.is(v, Comp) then
            v:off()
        end
    end
end

function Entity:has_active(...)
    local comps_attribute_as_string={...}
    for _, comp_name in ipairs(comps_attribute_as_string) do
        local comp=self[comp_name]
        -- print(comp_name, comp)
        if not comp or (Xtype.is(comp, Comp) and not comp.active) then
            return false
        end
    end
    return true
end

function Entity:has(...)
    local comps_attribute_as_string={...}
    for _, comp_name in ipairs(comps_attribute_as_string) do
        local comp=self[comp_name]
        -- print(self, comp_name, comp, comp.active)

        if not comp then
            return false
        end
    end
    return true
end

--===========================#
-- Character

E_Actor=Class('E_Actor', Entity)

function E_Actor:__construct(e, x, y, w, h)
    e = e or self
    Entity:__construct(e)
    --=
    e.c_b=C_Body(e, x, y, w, h)
    --=
    e.c_gravity=C_Gravity(e)
    e.c_move_hrz=C_MoveHrz(e)
    --=
    e.c_pad = C_Pad(e)
    e.c_event_listener = C_EventListener(e)
    --=
    e.c_anim=C_Anim(e, Atlas.Hero)
    e.c_anim:set('run')
    e.c_anim_dir = C_AnimDir(e)
    e.c_anim_dir:off()
end

--===========================#
-- Hero

E_Hero=Class('E_Hero', E_Actor)

function E_Hero:__construct(x, y)
    local e = self
    local w = 18
    local h = 30
    E_Actor:__construct(e, x - w*.5, y-h, w, h)
    --=
    e.c_b.dbg_outline = true
    e.c_b.dbg_outline_color = {0, 0, 1, 1}
    e.c_state_machine=C_StateMachine(e, St_HeroGround(e))
    e.c_state_machine.dbg_logs = false

    e.c_health = C_Health(e, 10)
    --=
    e.c_pad:add_key('up')
    e.c_pad:add_key('down')
    e.c_pad:add_key('left')
    e.c_pad:add_key('right')
    e.c_pad:add_key('a', 'space')
    --=
    e.guard_state_enabled = true
    e.is_hittable = true
    e.is_punchable = false
    e.is_shockable = true
    e.is_gunnable = true
    e.is_rokcketable = true
    --=
    e.c_guard = true
    e.is_guarding = false
    -- = 
    e.c_ladder = true
end

--===========================#
-- Enemy

E_Enemy=Class('E_Enemy', E_Actor)
E_Enemy.Type = {Base='Base', Gun='Gun', Rocket='Rocket', Bomb='Bomb', Ninja='Ninja', Monkey='Monkey'}

function E_Enemy:__construct(e, x, y, w, h, type, dir)
    e = e or self
    E_Actor:__construct(e, x, y, 10, 32)
    --=
    e.type = type or E_Enemy.Type.Base
    e.jewel_color=nil
    --=
    e.c_enemy = true
    e.c_ai = C_Ai(e)
    e.c_anim.atlas = Atlas.Enemy[e.type]
    e.c_anim.dir = dir or 1
    e.c_state_machine=C_StateMachine(e)
    e.c_state_machine.ground_state = St_EnGround
    e.c_state_machine:set(e.c_state_machine.ground_state(e))
    e.c_state_machine.dbg_logs = false
    --=
    e.is_hittable=true
    e.is_hittable_by_thrown=false
    e.is_gunnable = false
    e.is_rocketable = false
    --=
    local health_table = {
        Ninja=12, Gun=12, Rocket=12, Bomb=15, Base=6, Monkey=100
    }
    e.c_health = C_Health(e, health_table[e.type])
    --=
    e.c_pad.listen_to_keyboard = false
    e.c_pad:add_key('up')
    e.c_pad:add_key('down')
    e.c_pad:add_key('left')
    e.c_pad:add_key('right')
    e.c_pad:add_key('a')

    e.c_anim.dir = math.random(0, 1) == 0 and 1 or -1

    e.c_b.dbg_outline = true
    e.c_b.dbg_outline_color = {1, 0, 0, 1}
    e:off('c_move_hrz')
end

--===========================#
-- = E_BaseSoldier
--=#

E_BaseSoldier=Class('E_BaseSoldier', E_Enemy)

function E_BaseSoldier:__construct(e, spawn_x, spawn_y, type)
    e = e or self
    E_Enemy:__construct(e, spawn_x, spawn_y, 12, Tl.Dim * 0.8, type or E_Enemy.Type.Base)
    --=
    e.c_punch = C_Punch(e)
    e.c_pad:add_key('punch')

    e.c_grabbable = true
    e.is_grabbable = false

    e.c_ground_pickable = true
    e.is_pickable = false

    e.c_catchable = true
    e.is_catchable = false

    e.c_armlockable = true
    e.is_armlockable = false

    e.c_guard = true
    e.is_guarding = false

    e.c_riddable = true -- hero can fall on top of enemy
    e.is_riddable = false
    --=
    e.c_ladder = true
    e.c_dodge = true -- AI can dodge
    e.c_fall_from_edge = true -- AI can fall
end

--===========================#
-- = E_GunSoldier
--=#

E_GunSoldier=Class('E_GunSoldier', E_BaseSoldier)

function E_GunSoldier:__construct(spawn_x, spawn_y)
    local e = self
    E_BaseSoldier:__construct(e, spawn_x, spawn_y, E_Enemy.Type.Gun)
    --=
    e.c_gun = true
    e.c_pad:add_key('gun')
    e.c_pad:add_key('gun_duck')
end

--===========================#
-- = E_RocketSoldier
--=#

E_RocketSoldier=Class('E_Soldier', E_BaseSoldier)

function E_RocketSoldier:__construct(spawn_x, spawn_y)
    local e = self
    E_BaseSoldier:__construct(e, spawn_x, spawn_y, E_Enemy.Type.Rocket)
    --=
    e.c_rocket = true
    e.c_pad:add_key('rocket')
end

--===========================#
-- = E_BombSoldier
--=#

E_BombSoldier=Class('E_BombSoldier', E_BaseSoldier)

function E_BombSoldier:__construct(spawn_x, spawn_y)
    local e = self
    E_BaseSoldier:__construct(e, spawn_x, spawn_y, E_Enemy.Type.Bomb)
    --=
    e.c_bomb = true
    e.c_pad:add_key('bomb')
    e.c_gun = true
    e.c_pad:add_key('gun')
    e.c_pad:add_key('gun_duck')
end

--===========================#
-- = E_BombSoldier
--=#

E_Ninja=Class('E_Ninja', E_BaseSoldier)

function E_Ninja:__construct(spawn_x, spawn_y)
    local e = self
    E_BaseSoldier:__construct(e, spawn_x, spawn_y, E_Enemy.Type.Ninja)
    --=
    e.c_shuriken = true
    e.c_pad:add_key('shuriken')
    e.c_katana = C_Katana(e)
    e.c_pad:add_key('katana')
    e.c_dash = true
    e.c_pad:add_key('dash')
    e.c_jump_kick = true
    e.c_pad:add_key('jump_kick')

    e.c_punch = nil
    e.c_ladder = nil
    e.c_fall_from_edge = nil
end

--===========================#
-- = E_Monkey
--=#

E_Monkey=Class('E_Monkey', E_Enemy)

function E_Monkey:__construct()
    local e = self
    
    local spawn_x = 0
    local spawn_y = 0

    if (GAME) then
        local m = GAME.map
        spawn_x = m.x - 300
        spawn_y = m.y + m.h + 400
    end

    E_Enemy:__construct(e, spawn_x, spawn_y, 12, Tl.Dim * 0.8, E_Enemy.Type.Monkey)
    local c_sm = e.c_state_machine

    if (GAME) then
        local m = GAME.map
        local st_jump = St_Jump(e, m:tile_at_index(4, m.ih-3))
        c_sm:set(st_jump)
    else
        c_sm:set(St_MkGround)
    end

    if (GAME) and GAME.cam then
       GAME.cam:shake(1, 12)
    end

    c_sm.ground_state = St_MkGround
    -- c_sm.dbg_logs = true

    e.c_claw = true
    e.c_pad:add_key('claw')

    e.c_grab_hero = true
    e.c_pad:add_key('grab_hero')
end

--===========================#
-- = E_Projectile
--=#

E_Projectile=Class('E_Projectile', Entity)

function E_Projectile:__construct(self, v2_spawn, v2_dir, v2_pow, speed, anim_key, on_hit_spawn_e, e_owner, w, h)
    local e = self
    Entity:__construct(e)
    --=
    e.c_b=C_Body(e, v2_spawn.x, v2_spawn.y, w or 8, h or 2)
    e.c_anim=C_Anim(e, Atlas.Item)
    e.c_anim:set(anim_key)
    e.c_projectile = C_Projectile(e, v2_dir.x, v2_dir.y, speed, v2_pow, on_hit_spawn_e, e_owner)
    e.c_anim.dir = v2_dir.x
end

--===========================#

E_Bullet=Class('E_Projectile', E_Projectile)
function E_Bullet:__construct(x, y, dir_x, e_owner)
    local e = self
    local w = 8
    local h = 16
    E_Projectile:__construct(e,
        V2(x - w/2, y-4),
        V2(dir_x, 0),
        V2(Tl.Dim*3, -128),
        BULLET_SPEED, --260, -- Tl.Dim * 9,
        'bullet',
        E_FxBulletHit,
        e_owner,
        w, h
    )
    e.c_anim.oy = h-4
    e.c_b.dbg_outline = true
end

E_Shuriken=Class('E_Shuriken', E_Projectile)
function E_Shuriken:__construct(x, y, dir_x, dir_y, e_owner)
    local e = self
    E_Projectile:__construct(e,
        V2(x, y),
        V2(dir_x, dir_y),
        V2(Tl.Dim*3, -128),
        Tl.Dim * 9,
        'shuriken', 
        E_FxBulletHit,
        e_owner
    )
end

E_Rocket=Class('E_Projectile', E_Projectile)        
function E_Rocket:__construct(x, y, dir_x, e_owner)
    local e = self
    local w = 8
    local h = 20
    E_Projectile:__construct(
        e,
        V2(x, y-h/2),
        V2(dir_x, 0),
        V2(Tl.Dim*6, -192),
        ROCKET_SPEED,-- 336,
        'rocket',
        E_Explosion,
        e_owner,
        w, 
        h
    )
    e.c_fx_trail = C_FxTrail(e, dir_x, E_FxRocketSmoke, 0.1)
    e.c_anim.oy = h/2-2
    -- e.c_b.dbg_outline = true
end

E_Mine=Class('E_Mine', E_Projectile)        
function E_Mine:__construct(x, y)
    local e = self
    -- E_Projectile:__construct(
    --     e,
    --     V2(x,y),
    --     V2(0,0),
    --     V2(Tl.Dim*4, -192),
    --     0,
    --     'mine',
    --     E_Explosion
    -- )
    local e = self
    Entity:__construct(e)
    --=
    e.c_b=C_Body(e, x-6, y-8, 12, 8)
    
    e.c_anim=C_Anim(e, Atlas.Item)
    e.c_anim:set('mine')
    -- e.c_projectile = C_Projectile(e, v2_dir.x, v2_dir.y, speed, v2_pow, on_hit_spawn_e)
    -- e.c_anim.dir = 1
    e.c_b.dbg_outline = true

    Entity:__construct(e)
    e.c_mine = C_Mine(e)
end

--===========================#

E_Fx=Class('E_Fx', Entity)
function E_Fx:__construct(self, mid_x, mid_y, anim_key)
    local e = self
    Entity:__construct(e)
    --=
    e.c_anim=C_Anim(e, Atlas.Fx)
    e.c_anim:set(anim_key)

    local anim_w = e.c_anim.props.frame_w
    local anim_h = e.c_anim.props.frame_h

    e.c_b=C_Body(e, mid_x, mid_y, anim_w, anim_h)
    e.c_b:set_static()

    e.c_b:set_mid_x(mid_x)
    e.c_b:set_mid_y(mid_y)
    -- e.c_anim:set_origin(anim_w * 0.5)
    e.c_del_on_anim_over = C_DelOnAnimOver(e)

    -- e.c_b.dbg_outline = true
end

--===========================#

E_FxKatanaTrail=Class('E_FxKatanaTrail', E_Fx)
function E_FxKatanaTrail:__construct(mid_x, mid_y, dir)
    E_Fx:__construct(self, mid_x, mid_y, 'katana_trail')
    --=
    self.c_anim.dir = dir
end

E_FxBulletHit=Class('E_FxBulletHit', E_Fx)
function E_FxBulletHit:__construct(mid_x, mid_y, dir)
    E_Fx:__construct(self, mid_x, mid_y, 'on_bullet_hit')
    --=
    self.c_anim.dir = dir
end

E_FxRocketSmoke=Class('E_FxRocketSmoke', E_Fx)
function E_FxRocketSmoke:__construct(mid_x, mid_y)
    E_Fx:__construct(self, mid_x, mid_y, 'rocket_smoke')
end

E_FxRocketAiming=Class('E_FxRocketAiming', E_Fx)
function E_FxRocketAiming:__construct(mid_x, mid_y, dir)
    E_Fx:__construct(self, mid_x, mid_y, 'rocket_aiming')
    -- self.c_anim:blink(0.03)
    self.c_anim.dir = dir
    self.c_del_on_anim_over:off()
    -- self.c_b.dbg_outline = true
end

E_FxEnemyChaseMark=Class('E_FxEnemyChaseMark', E_Fx)
function E_FxEnemyChaseMark:__construct(e_en)
    local spawn_x = e_en.c_b:mid_x()
    local spawn_y = e_en.c_b:top() - 14
    E_Fx:__construct(self, spawn_x, spawn_y, 'enemy_chase_mark')
end

E_FxFlare=Class('E_FxFlare', E_Fx)
function E_FxFlare:__construct(mid_x, mid_y)
    E_Fx:__construct(self, mid_x, mid_y, 'flare')
end

E_FxItemPickedUp=Class('E_FxItemPickedUp', E_Fx)
function E_FxItemPickedUp:__construct(mid_x, mid_y)
    E_Fx:__construct(self, mid_x, mid_y, 'item_picked_up')
end

--===========================#

E_Explosion=Class('E_Explosion', Entity)

function E_Explosion:__construct(mid_x, mid_y)
    Entity:__construct(self)
    --=
    local e = self
    Game:emit_flare_particles(mid_x, mid_y)
end


--===========================#
-- TILE

E_Tile=Class('E_Tile', Entity)

function E_Tile:__construct(x, y, ix, iy, type)
    Entity:__construct(self)
    local e = self

    -- = body pos & dim
    -- local x = (ix-1)*Tl.Dim
    local w, h = Tl.Dim, Tl.Dim
  
    x = x + (ix-1)*Tl.Dim
    y = y + (iy-1)*Tl.Dim

    if type==Tl.Type.Platform then
        h = 10
    end

    --=
    e.c_b=C_Body(e, x, y, w, h)
    e.c_b:set_static()

    local props=GAME.map:get_tile_properties(ix, iy, type)

    e.c_tile=C_Tile(e, ix, iy, type, props)
    --=
    e.ix=ix
    e.iy=iy
    e.type=type

    -- = quad
    local rand_quad_odds = {
        0, 8, 3, 8, 0, 0
    }
    local is_rand_quad = love.math.random(1, rand_quad_odds[type]) == 1

    if type == Tl.Type.Wall then
        local subquads = GAME.map.__quads[type]

        if ix == 1 then
            e.quad = subquads[1]
        elseif ix == GAME.map.iw then
            e.quad = subquads[2]
        elseif is_rand_quad then
            e.quad = subquads[love.math.random(3, #subquads)]
        end
    elseif type == Tl.Type.Empty then
        local subquads = GAME.map.__quads[type]

        if ix == 1 then
            e.quad = subquads[1]
        elseif ix == GAME.map.iw then
            e.quad = subquads[2]
        elseif is_rand_quad then
            e.quad = subquads[love.math.random(3, #subquads)]
        end
    end

    if not e.quad then
        e.quad = GAME.map.__tileset_quads[type]
    end
end

--===========================#
-- RECT


E_Rect=Class('E_Rect', Entity)

function E_Rect:__construct(x, y, w, h)
    Entity:__construct(self)
    local e = self
    --=
    e.c_b=C_Body(e, x, y, w, h)
    e.c_b.is_static = true
    e.c_b.dbg_outline = true
end


--===========================#

E_ScoreTxt=Class('E_ScoreTxt', Entity)

function E_ScoreTxt:__construct(mid_x, mid_y, points, e_source)
    Entity:__construct(self)
    local e = self
    --=
    e.c_text = C_Text(e, '' .. points)
    e.c_b=C_Body(e, mid_x, mid_y, 2, 2)
    e.c_b:set_static()
    e.c_b:set_mid_x(mid_x -  e.c_text.o_text:getWidth() * 0.5)
    e.c_b:set_mid_y(mid_y -  e.c_text.o_text:getHeight() * 0.5)
    e.c_b.vy = -12

    e.c_blink = C_Blink(e, 0.08)
    e:off('c_blink')

    e.e_source = e_source
end

--===========================#

E_Item=Class('E_Item', Entity)

function E_Item:__construct(self, mid_x, bot)
    Entity:__construct(self)
    --=
    local e = self
    local w = 10
    local h = 18

    e.c_b=C_Body(e, mid_x-w*0.5, bot-h, w, h)
    e.c_b:set_mid_x(mid_x)
    e.c_b.vy = -192
    e.c_b.bounce_y = 0.5

    e.c_gravity=C_Gravity(e)
    e.c_pickable = C_Pickable(e)
end

--===========================#

E_Jewel=Class('E_Jewel', E_Item)
E_Jewel.Color = {Nil='nil', Red='red', Orange='orange', Blue='blue', Green='green', Yellow='yellow', Cyan='cyan', Purple='purple', Pink='pink'}

function E_Jewel:__construct(mid_x, bot, color)
    E_Item:__construct(self, mid_x, bot)
    local e = self
    --=
    e.c_jewel = C_Jewel(e, color)
    e.c_anim=C_Anim(e, Atlas.Jewel):set(color)
    e.c_anim:pause()
    e.c_anim:set_origin(nil, 2)
    -- e.c_b.dbg_outline = true
    -- e.c_b.dbg_outline_color = {1, 0, 0, 1}
end

--===========================#

E_LifeUp=Class('E_LifeUp', E_Item)
E_LifeUp.Size = {Md='md', Sm='sm', }

function E_LifeUp:__construct(mid_x, bot, size)
    E_Item:__construct(self, mid_x, bot)
    local e = self
    --=
    e.c_life_up = C_LifeUp(e, size)
    e.c_anim=C_Anim(e, Atlas.Item):set('life_up_' .. size)
    e.c_anim:set_origin(nil, 4)
end

--===========================#

E_Debris=Class('E_Debris', Entity)
E_Debris.Size = {Xl='xl', Md='md', Sm='sm'}

function E_Debris:__construct(x, y, type)
    Entity:__construct(self)
    local e = self

    type = type or E_Debris.Size.Sm
    --=
    e.c_b=C_Body(e, x, y, 2, 2)
    e.c_b.is_coll_disabled = true
    e.c_b.vy = -192
 
    e.c_gravity=C_Gravity(e)
    e.c_anim=C_Anim(e, Atlas.Particle.Debris):set(type)
    e.c_debris = C_Debris(e)
end