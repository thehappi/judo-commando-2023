local Tiny = Tiny or require 'lib.tiny'

S_Collision=Tiny.processingSystem()
S_Collision.active=false;

function S_Collision:filter(e)
    return e:has_active('c_b') and not Xtype.is(e, E_Enemy) and not e.c_debris--and e.c_b.is_static == false 
        -- and not e.c_b.is_coll_disabled
end

function S_Collision.__filter_colls(e,o) -- = un filter pour la map & autre entity static + un autre pour les entity dynamic
    local c_b=e.c_b
    local c_sm = e.c_state_machine
  
    if o.name == 'building' then
        return 'slide'
    end

    if Xtype.is(e, E_Projectile) and Xtype.is(o, E_Actor) then
        return 'cross'
    end

    if Xtype.is(e, E_Hero) then
        if Xtype.is(o, E_Enemy) then
            return 'cross'
        end
    end

    if e:has_active('c_pickable') and Xtype.is(o, E_Hero) then
        -- if Xtype.is(e, E_Jewel) then
        --     -- E_Jewel
        --     print(e, e:has_active('c_b'), e.c_b.is_static == false,e:has_active('c_pickable' ))
        -- end
        return 'cross'
    end

    if Xtype.is(e, E_Enemy) and Xtype.is(o, E_Hero) then
        return 'cross'
    end

    -- thrown enemy collides with others
    if Xtype.is(e, E_Enemy) and Xtype.is(o, E_Enemy) then
        return 'cross'
    end

    if Xtype.is(o, E_Tile) then
        local e_tile = o
        local c_tile = o.c_tile

        -- = while climbing ladder => pass through Ladder Wall
        if c_tile:has_all_props(Tl.Prop.Ladder, Tl.Prop.Wall) and c_sm then
            if c_sm:is(St_Ladder) or c_sm:is(St_MeteorCombo) then
                return 'cross'
            elseif c_sm:is(St_HeroFall) then
                if c_b:right() > e_tile.c_b:left() and c_b:left() < e_tile.c_b:right() then
                    return 'cross'
                else
                    return 'slide'
                end
            end
        end

        if c_sm
            and (c_sm:is(St_EnMeteorCombo) or c_sm:is(St_EnIsHit) and e.c_b.vy > 0)
        then
            if c_tile:has_all_props(Tl.Prop.Ladder, Tl.Prop.Wall) then
                return 'cross'
            end
        end

        if c_tile:has_prop(Tl.Prop.Empty) then
            return nil
        end

        if c_tile:has_all_props(Tl.Prop.Ladder, Tl.Prop.Wall) then
            return 'slide'
        end

        if c_tile:has_all_props(Tl.Prop.Ladder, Tl.Prop.Ground) then
            -- local n_u =  c_tile:neighbor(0, -1)
            -- if n_u and n_u.c_tile:has_prop(Tl.Prop.Empty) then
                return 'cross'
            -- end
        end

        if c_tile:has_prop(Tl.Prop.Platform) then
            return 'cross'
        end

        if c_tile:has_prop(Tl.Prop.Ground) then
            return 'slide'
        end

        if c_tile:has_prop(Tl.Prop.Wall) then
            return 'slide'
        end
    end

end

function S_Collision:process(e, dt)
    local c_b=e.c_b
    -- print(c_b.vy)

    if c_b.new_w then
        local diff_w = c_b.w - c_b.new_w
        c_b.w = c_b.new_w
        c_b.x = c_b.x + diff_w * 0.5
        c_b.new_w=nil
        GAME.bump_world:update(e, c_b.x, c_b.y, c_b.w, c_b.h)
    end

    if c_b.new_h then
        local diff_h = c_b.h - c_b.new_h
        c_b.h = c_b.new_h
        c_b.y = c_b.y + diff_h
        c_b.new_h=nil
        GAME.bump_world:update(e, c_b.x, c_b.y, c_b.w, c_b.h)
    end

    local c_sm = e.c_state_machine

    c_b.prev_x = c_b:mid_x()
    c_b.prev_y = c_b:bot()

    local goal_x=c_b.x + c_b.vx * dt
    local goal_y=c_b.y + c_b.vy * dt

    if e.c_b.is_static == false then
        goal_x, goal_y, colls, _ = GAME.bump_world:check(e, goal_x, goal_y, c_b.filter == nil and self.__filter_colls or c_b.filter)
    else
        goal_x, goal_y, colls, _ = GAME.bump_world:move(e, goal_x, goal_y, nil)
        return
    end

    c_b.has_hit_wall = false

    c_b.colls=colls
    c_b.__colls_with_tile = {}
    c_b.__colls_with = {}

    c_b.has_hit_ground = nil
    c_b.has_hit_ceil = nil
    c_b.can_stick_platf = nil

     -- = is entity still on ground ?
    --  if c_b.is_on_ground then
        -- local _, len = GAME.bump_world:queryRect(goal_x, goal_y+c_b.h, c_b.w, 4, function(e_other)
        --     return Xtype.is(e_other, E_Tile) and e_other.c_tile:has_prop(Tl.Prop.Ground)
        -- end)
        -- c_b.is_on_ground = len > 0
    -- end
    if c_b.is_on_ground and c_b.vy < 0 then
        c_b.is_on_ground = false
    end

    -- = special collision handling
    for _, coll in ipairs(colls) do
        local o = coll.other
        if Xtype.is(e, E_Rocket) then
            o.c_b.vx = 0
            e.c_b.vx = 0
        end
        -- = Tiles
        if Xtype.is(o, E_Tile) then
            local e_tl=o
            local c_tl=o.c_tile
            if Xtype.is(e, E_Rocket) then
                GAME.map:destroy_tile(e_tl.ix, e_tl.iy, coll.normal.x)
            end
            -- = hit ground
            if not c_b.is_on_ground and c_b.vy > 0 and coll.normal.y == -1 and c_tl:has_prop(Tl.Prop.Ground) and c_b:bot() < e_tl.c_b:top() + 8 then
            -- if not c_b.is_on_ground and c_tl:has_prop(Tl.Prop.Ground) and c_b:bot() < e_tl.c_b:top() + 8 then
                c_b.has_hit_ground = coll
                c_b.is_on_ground = coll
                c_b.e_ground_tl = e_tl

                -- bounce_y
                if c_b.bounce_y then
                    c_b.vy = -c_b.bounce_y * c_b.vy
                    if c_b.vy > -1 then
                        c_b.vy = 0
                        c_b.bounce_y = nil
                    end
                end

                -- = atterir sur plateformes
                if c_tl:has_prop(Tl.Prop.Platform) or c_tl:has_all_props(Tl.Prop.Ladder,Tl.Prop.Ground) then
                    goal_y = e_tl.c_b:top() - c_b.h
                    
                    -- if (Xtype.is(e, E_Jewel)) then
                    --     print('jewel', goal_y)
                    -- end
                    if e.c_gravity then
                        e.c_gravity:off()
                    end
                    e.c_b.vy = 0

                    -- print('la', goal_y)

                end
                Signal.emit('has_hit_ground', e) -- emit
            end
            -- = hit ceiling
            if c_b.vy < 0 and coll.normal.y == 1 and c_tl:has_prop(Tl.Prop.Ceil) and e:has_active('c_gravity') then
                if Xtype.is(e, E_Enemy) then
                   GAME:hit_ceil(coll)
                end
                c_b.has_hit_ceil = coll
            end
            -- = hit wall
            if not c_b.has_hit_wall and coll.normal.x ~= 0 and c_tl:has_prop(Tl.Prop.Wall) then
                -- print('en hit wall co')
                if Xtype.is(e, E_Enemy) and e.c_state_machine:is(St_EnIsHit) then
                    GAME:hit_wall(coll)
                end
                c_b.has_hit_wall = coll
            end
            -- = test => hang to platform
            if Xtype.is(e, E_Hero) then
                if (c_b.is_platf_enabled
                    and not e.c_pad:is_pressed('down')
                    and c_b.vy > -32
                    and c_tl:has_prop(Tl.Prop.Platform)
                    and c_b:top() >= e_tl.c_b:top()-4
                    and c_b:top() <= e_tl.c_b:top()+16
                ) then
                    c_b.can_stick_platf = coll
                end
            end
            table.insert(c_b.__colls_with_tile, coll)
        else
            local saveCollByClass = function (coll, root_instance)
                local o = root_instance
                local name = Xtype.name(Xtype.get(o))

                -- print(Xtype.tostring2(o))
                if type(c_b.__colls_with[name]) ~= "table" then
                    c_b.__colls_with[name] = {}
                end

                table.insert(c_b.__colls_with[name], coll)
            end
            saveCollByClass(coll, o)
            -- print('add : ', Xtype.name(Xtype.get(o)))
        end
    end

    local ground_colls = {}
    local len = 0
    -- = is entity still on ground ?
    if c_b.is_on_ground then -- and not c_b.has_hit_ground then
        ground_colls, len = GAME.bump_world:queryRect(goal_x, goal_y+c_b.h, c_b.w, 4, function(e_other)
            return Xtype.is(e_other, E_Tile) and e_other.c_tile:has_prop(Tl.Prop.Ground)
        end)
        c_b.is_on_ground = len > 0
    end

    -- = 
    c_b.is_on_platform = false
    if c_b.is_on_ground then
        _, len = GAME.bump_world:queryRect(goal_x, goal_y+c_b.h, c_b.w, 4, function(e_other)
            return Xtype.is(e_other, E_Tile) and e_other.c_tile:has_prop(Tl.Prop.Platform)
        end)

        if len > 0 then
            c_b.is_on_platform = true
            -- c_b.ground_colls = ground_colls
        end
    end
    c_b.ground_colls = ground_colls


--  -- = update actual position
    -- if goal_x ~= goal_x then
        -- print(e, e.c_b.x, e.c_b.vx, e.c_state_machine.__cur_state)
        -- error('goal_x is NaN')
    -- end
    e.c_b.x = goal_x
    e.c_b.y = goal_y

    -- ??? should i update bump pos also here ????
    -- GAME.bump_world:update(e, c_b.x, c_b.y, c_b.w, c_b.h)

end

--===========================#
-- 

S_UpdateBumpPosition=Tiny.processingSystem()
S_UpdateBumpPosition.active=false;

function S_UpdateBumpPosition:filter(e)
    return e:has_active('c_b') and not e.c_b.is_static
end

function S_UpdateBumpPosition:process(e, dt)
    local c_b = e.c_b
    GAME.bump_world:update(e, c_b.x, c_b.y, c_b.w, c_b.h)
end








S_EnemyCollision=Tiny.processingSystem()
S_EnemyCollision.active=false;
S_EnemyCollision.filter=Tiny.requireAll("c_enemy");

function S_EnemyCollision.__filter_colls(e,o) -- = un filter pour la map & autre entity static + un autre pour les entity dynamic
    local c_b=e.c_b
    local c_sm = e.c_state_machine

    if o.name == 'building' then
        return 'slide'
    end

    if Xtype.is(o, E_Hero) then
        return 'cross'
    end

    -- thrown enemy collides with others
    if Xtype.is(o, E_Enemy) then
        return 'cross'
    end

    if Xtype.is(o, E_Tile) then
        local e_tile = o
        local c_tile = o.c_tile

        -- if c_sm:is(St_EnIsHit) then
            -- print('====>', o.c_tile.index.x, o.c_tile.index.y, e.c_state_machine:get())
        -- end

        -- = while climbing ladder => pass through Ladder Wall
        if c_tile:has_all_props(Tl.Prop.Ladder, Tl.Prop.Wall) and c_sm then
            -- print('lali', e, c_sm.__cur_state, c_sm.__new_state)
            if c_sm:is(St_EnIsHit) then
                return c_b.vy > 0 and 'cross' or 'slide'
            end
        end

        -- = while climbing ladder => pass through Ladder Wall
        if c_sm
            and c_sm:is(St_Ladder)
        then
            if c_tile:has_all_props(Tl.Prop.Ladder, Tl.Prop.Wall) then
                -- print('lalala2')
                return 'cross'
            end
        end

        if c_sm
            and (c_sm:is(St_EnMeteorCombo) or c_sm:is(St_EnIsHit) and e.c_b.vy > 0)
        then
            if c_tile:has_all_props(Tl.Prop.Ladder, Tl.Prop.Wall) then
                -- print('lalala')
                return 'cross'
            end
        end

        if c_tile:has_prop(Tl.Prop.Empty) then
            return nil
        end

        if c_tile:has_all_props(Tl.Prop.Ladder, Tl.Prop.Wall) then
            return 'slide'
        end

        if c_tile:has_all_props(Tl.Prop.Ladder, Tl.Prop.Ground) then
            return 'cross'
        end

        if c_tile:has_prop(Tl.Prop.Platform) then
            return 'cross'
        end

        if c_tile:has_prop(Tl.Prop.Ground) then
            return 'slide'
        end

        if c_tile:has_prop(Tl.Prop.Wall) then
            return 'slide'
        end
    end

    if o:has_active('c_mine') then
        if c_sm:is(St_EnIsHit) then
            return 'cross'
        else
            return 'cross'
        end
    end
end

function S_EnemyCollision:updateW(e)
    local c_b=e.c_b
    local diff_w = c_b.w - c_b.new_w
    c_b.x = c_b.x + diff_w * 0.5 -- indispensable
    c_b.w = c_b.new_w

    GAME.bump_world:update(e, c_b.x, c_b.y, c_b.w)

    local _, _, cols, _ = GAME.bump_world:check(e, c_b.x, c_b.y, function(e, o)
        if Xtype.is(o, E_Tile) and o.c_tile:has_prop(Tl.Prop.Wall) and not o.c_tile:has_prop(Tl.Prop.Ladder) then
            return 'slide'
        end
        return nil
    end)
    -- print('OKKKKKKKKKKKKKKKKKKKK', diff_w, c_b.new_w)
    if #cols > 0 then
        c_b.x = cols[1].touch.x -- méfiance
    end
    GAME.bump_world:update(e, c_b.x, c_b.y, c_b.w)
end

function S_EnemyCollision:updateH(e)
    local c_b=e.c_b
    local diff_h = c_b.h - c_b.new_h
    -- print('new_w', c_b.new_w)
    c_b.y = c_b.y + diff_h * c_b.oy -- indispensable
    c_b.h = c_b.new_h
    GAME.bump_world:update(e, c_b.x, c_b.y, c_b.w, c_b.h)

    local _, _, cols, _ = GAME.bump_world:check(e, c_b.x, c_b.y, function(e, o)
        if Xtype.is(o, E_Tile) and o.c_tile:has_prop(Tl.Prop.Wall) and not o.c_tile:has_prop(Tl.Prop.Ladder) then
            return 'slide'
        end
        return nil
    end)
    if #cols > 0 then
        c_b.y = cols[1].touch.y
    end
    GAME.bump_world:update(e, c_b.x, c_b.y, c_b.w, c_b.h)
end

-- function S_EnemyCollision:updateH(e)
--     local c_b=e.c_b
--     local diff_h = c_b.h - c_b.new_h

--     c_b.h = c_b.new_h
--     c_b.y = c_b.y + diff_h
--     GAME.bump_world:update(e, c_b.x, c_b.y, c_b.w, c_b.h)
-- end

function S_EnemyCollision:process(e, dt)
    local c_b=e.c_b

    if c_b.new_w then
        self:updateW(e)
        c_b.new_w=nil
    end

    if c_b.new_h then
        self:updateH(e)
        c_b.new_h=nil
    end

    local c_sm = e.c_state_machine

    c_b.prev_x = c_b:mid_x()
    c_b.prev_y = c_b:bot()

    local goal_x=c_b.x + c_b.vx * dt 
    local goal_y=c_b.y + c_b.vy * dt
    local colls={}

    goal_x, goal_y, colls, _ = GAME.bump_world:check(e, goal_x, goal_y, c_b.filter == nil and self.__filter_colls or c_b.filter)

    c_b.has_hit_wall = false

    c_b.colls=colls
    c_b.__colls_with_tile = {}
    c_b.__colls_with = {}

    c_b.has_hit_ground = nil
    c_b.has_hit_ceil = nil
    c_b.can_stick_platf = nil

    self.destroy_tile = {}

    -- = special collision handling
    for _, coll in ipairs(colls) do
        local o = coll.other
        -- = Tiles
        if Xtype.is(o, E_Tile) then
            local e_tl=o
            local c_tl=o.c_tile

            -- = hit ground
            if not c_b.is_on_ground and c_b.vy > 0 and coll.normal.y == -1 and c_tl:has_prop(Tl.Prop.Ground) and c_b:bot() < e_tl.c_b:top() + 8 then
                -- print('en hit ground')
                if not c_tl:has_prop(Tl.Prop.Platform) or c_b.is_platf_enabled then
                    c_b.has_hit_ground = coll
                    c_b.is_on_ground = coll
                end

                -- = atterir sur plateformes
                if (c_tl:has_prop(Tl.Prop.Platform) and c_b.is_platf_enabled) or c_tl:has_all_props(Tl.Prop.Ladder,Tl.Prop.Ground) then
                    goal_y = e_tl.c_b:top() - c_b.h
                    e.c_gravity:off()
                    e.c_b.vy = 0
                end
            end

            -- = hit ceiling
            if c_b.vy < 0 and coll.normal.y == 1 and c_tl:has_prop(Tl.Prop.Ceil) then
                print('en hit ceil')
                if Xtype.is(e, E_Enemy) then
                   GAME:hit_ceil(coll)
                end
                c_b.has_hit_ceil = coll
            end
            -- = hit wall
            if not c_b.has_hit_wall and coll.normal.x ~= 0 and c_tl:has_prop(Tl.Prop.Wall) then
                -- print('en hit wall co', coll.type, e.c_state_machine:get())

                c_b.has_hit_wall = coll
                if Xtype.is(e, E_Enemy) and e.c_state_machine:is(St_EnIsHit) then
                    GAME:hit_wall(coll)
                    -- c_b.vy = -192
                    -- if not c_tl:is_ground() then
                        -- table.insert(self.destroy_tile, {e_tl=e_tl, coll=coll})
                        --     e.c_state_machine:get():onHitWall()
                        -- c_b.has_hit_wall = nil
                        -- GAME.map:destroy_tile(e_tl.ix, e_tl.iy, coll.normal.x)
                        -- goal_x=c_b.x + c_b.vx * dt
                        --     -- goal_y=c_b.y + c_b.vy * dt
                        -- return
                    -- end
                end
            end

            table.insert(c_b.__colls_with_tile, coll)
        else
            local saveCollByClass = function (coll, root_instance)
                local o = root_instance
                local name = Xtype.name(Xtype.get(o))

                if type(c_b.__colls_with[name]) ~= "table" then
                    c_b.__colls_with[name] = {}
                end

                table.insert(c_b.__colls_with[name], coll)
            end 
            saveCollByClass(coll, o)
        end
    end

    -- if #self.destroy_tile == 1 then
    --     local e_tl=self.destroy_tile[1].e_tl
    --     local coll=self.destroy_tile[1].coll
    --     self.destroy_tile = nil
        
    --     c_b.has_hit_wall = nil
    --     GAME.map:destroy_tile(e_tl.ix, e_tl.iy, coll.normal.x)
    --     goal_x=c_b.x + c_b.vx * dt
    -- end
    -- = is entity still on ground ?
    if c_b.is_on_ground and not c_b.has_hit_ground then
        local _, len = GAME.bump_world:queryRect(goal_x, goal_y+c_b.h, c_b.w, 4, function(e_other)
            return Xtype.is(e_other, E_Tile) and e_other.c_tile:has_prop(Tl.Prop.Ground)
        end)
        c_b.is_on_ground = len > 0
    end
    -- = 
     if c_b.is_on_ground then
        local _, len = GAME.bump_world:queryRect(goal_x, goal_y+c_b.h, c_b.w, 4, function(e_other)
            return Xtype.is(e_other, E_Tile) and e_other.c_tile:has_prop(Tl.Prop.Platform)
        end)
        c_b.is_on_platform = len > 0
    end
    -- = update actual position
    if goal_x ~= goal_x then
        -- print(e, e.c_b.x, e.c_b.vx, e.c_state_machine.__cur_state)
        goal_x = e.c_b.x
        -- error('goal_x is NaN')
    end
    if math.abs(goal_x - e.c_b.x) > 10 then
        goal_x = e.c_b.x + e.c_b.vx * dt
    end
    if math.abs(goal_y - e.c_b.y) > 10 then
        goal_y = e.c_b.y + e.c_b.vy * dt
    end
    e.c_b.x = goal_x
    e.c_b.y = goal_y
end