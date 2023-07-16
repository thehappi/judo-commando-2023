local C_Body=Class('C_Body', Comp)

function C_Body:__construct(e, x, y, w, h)
    Comp.__construct(self, e)
    -- = physic
    self.x=x or 0 -- readonly, use set_x()
    self.y=y or 0 -- readonly, use set_y()
    self.w=w or 1 -- readonly, use set_w()
    self.h=h or 1 -- readonly, use set_h()
    self.vx=0
    self.vy=0
    self.oy = 1
    --=
    self.acc_y=0
    self.acc_x=0
    -- = collision
    self.colls = {}
    self.__colls_with_tile = {}
    self.__colls_with = {}
    -- = a mettre coté components ?
    self.is_on_ground=nil
    self.is_on_platform=nil
    --=
    self.has_hit_ground=nil
    self.has_hit_ceil=nil
    --=
    self.dbg_outline=false
    self.draw_outile_color={0,1,0,1}
    --=
    self.is_ladder_enabled = true
    self.is_platf_enabled = true
    self.is_catchable = true
    self.is_hittable = true
    --=
    self.is_static = false
    self.coll_filter = nil -- depreciated
    self.filter = nil
    self.color = {1,1,1}
    if (GAME) then
        GAME.bump_world:add(e, self.x, self.y, self.w, self.h)
    end
end

function C_Body:colls_with(e_classname)
    return self.__colls_with[e_classname] or {}
end

function C_Body:set_static()
    self.filter = function() return nil end
    self.is_coll_disabled = true
    -- self.is_static = true
end

function C_Body:set_dynamic()
    self.filter = nil
end


--======== POS GETTERS =========--

function C_Body:dist_to(c_b)
    return math.sqrt( self:dist_x(c_b)^2 + self:dist_y(c_b)^2 )
end

function C_Body:dist_to_xy(x, y)
    return math.sqrt( (self:mid_x()-x)^2 + (self:mid_y()-y)^2 )
end

function C_Body:angle_to_xy(x, y)
    -- local anim_dir = e.c_anim.dir
    -- local spawn_at = V2(c_b:mid_x()+anim_dir*16, c_b:bot()-26)
    
    -- local e_shuriken = E_Shuriken(spawn_at.x, spawn_at.y, 0, 0)

    local adj = math.abs(self:mid_x() - x)
    local opp = self:mid_y() - y
    local angle = math.atan2(opp, adj)

    return angle
    
    -- e_shuriken.c_projectile.dir_x = math.cos(angle) * anim_dir
    -- e_shuriken.c_projectile.dir_y = -math.sin(angle)
end

function C_Body:dist_x(c_b)
    return self:mid_x() - c_b:mid_x()
end

function C_Body:dist_y(c_b)
    return self:bot() - c_b:bot()
end

function C_Body:bot()
    return self:top()+self.h
end

function C_Body:top()
    return self.y
end

function C_Body:right()
    return self:left()+self.w
end

function C_Body:left()
    return self.x
end

function C_Body:mid_x()
    return self:left()+self.w*.5
end

function C_Body:back()
    return self:mid_x()-self.e.c_anim.dir * self.w * .5
end

function C_Body:mid_y()
    return self:top()+self.h*.5
end

function C_Body:mid()
    return self:mid_x(), self:mid_y()
end

function C_Body:is_y_aligned(c_b)
    return math.abs(self:bot() - c_b:bot()) < 4
end

--======== POS SETTERS =========--

function C_Body:set_x(x, ignore_collision)
    local c_b = self.e.c_b
    self.x = x

    if ignore_collision == nil or ignore_collision == false then
        self.x, _, _, _ = GAME.bump_world:check(self.e, self.x, self.y, c_b.filter == nil and S_Collision.__filter_colls or c_b.filter)
    end
    GAME.bump_world:update(self.e, self.x, self.y, self.w, self.h)
end

function C_Body:set_y(y, ignore_collision)
    local c_b = self.e.c_b
    self.y = y
    if ignore_collision == nil or ignore_collision == false then
        _, self.y, _, _ = GAME.bump_world:check(self.e, self.x, self.y, c_b.filter == nil and S_Collision.__filter_colls or c_b.filter)
    end
    GAME.bump_world:update(self.e, self.x, self.y, self.w, self.h)
end

function C_Body:set_w(w)
    self.new_w = w
    -- GAME.bump_world:update(self.e, self.x, self.y, self.w, self.h)
end

function C_Body:set_h(h)
    self.new_h = h
    -- GAME.bump_world:update(self.e, self.x, self.y, self.w, self.h)
end


function C_Body:set_bot(y, ignore_collision)
    self:set_y( y-self.h, ignore_collision )
end

function C_Body:set_top(y, ignore_collision)
    self:set_y( y, ignore_collision )
end

function C_Body:set_left(x, ignore_collision)
    self:set_x( x, ignore_collision )
end

function C_Body:set_right(x, ignore_collision)
    self:set_x( x-self.w, ignore_collision )
end

function C_Body:set_mid_x(x, ignore)
    self:set_x( x-self.w*.5, ignore )
end

function C_Body:set_mid_y(y, ignore)
    self:set_y( y-self.h*.5, ignore )
end

function C_Body:set_mid(x, y)
    self:set_mid_x(x)
    self:set_mid_y(y)
end

function C_Body:set_vec(x, y)
    self.vx = x or self.vx
    self.vy = y or self.vy
end

function C_Body:move_x(x)
    self:set_x( self.x + x )
end

function C_Body:move_y(y)
    self:set_y( self.y + y )
end

function C_Body:intersects(x1, y1, x2, y2)
    if x2 < x1 then
        local tmp = x2
        x2 = x1
        x1 = tmp
    end
    if y2 < y1 then
        local tmp = y2
        y2 = y1
        y1 = tmp
    end
    return self.x < x2 and self.x+self.w > x1 and self.y < y2 and self.y+self.h > y1
end

function C_Body:set_oy(oy)
    self.oy = oy
end

return C_Body