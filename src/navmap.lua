NavMap=Class('NavMap')
NavTile=Class('NavTile')
NavAction=Class('NavAction')

NavAction.Type = {Jump='Jump', Fall='Fall', Ladder='Ladder'}

function NavTile:__construct(ix, iy)
	self.ix = 0
	self.iy = 0
    self.tl = GAME.map:tile_at_index(ix, iy)
    self.from = {}
    self.up = {}
    self.down = {}
    self.up_2 = {
        Ladder={}, Jump={}, Fall={}
    }
    self.down_2 = {
        Ladder={}, Jump={}, Fall={}
    }
    assert(self.tl ~= nil, 'err: '..ix..' '..iy)
end

function NavTile:insert_action(nav_action, vdir)
    local t = nil

    if vdir == 1 then
        table.insert(self.down, nav_action)
        t = self.down_2
    elseif vdir == -1 then
        table.insert(self.up, nav_action)
        t = self.up_2
    else
        return
    end

    table.insert(t[nav_action.type], nav_action)
end

function NavAction:__construct(type, nv_tl_src, nv_tl_dest, dir) -- action = jump ; fall ; ladder
    self.type = type
    self.src = nv_tl_src
    self.dest = nv_tl_dest
    self.dir = dir

    if nv_tl_dest and type ~= NavAction.Type.Fall then
        table.insert(nv_tl_dest.from, nv_tl_src)
    end

    if type == NavAction.Type.Jump then
        local dist_ih = math.abs(nv_tl_dest.tl.iy - nv_tl_src.tl.iy)
        -- if dist_ih > 3 then
            -- print(dist_ih, nv_tl_src.iy, nv_tl_dest.iy)
        -- end
    end

    -- if type == NavAction.Type.Fall then
    --     table.insert(GAME.__dbg_segments, {color={1, 0, 0}, x1=self.src, y1=, x2=, y2=}
    -- end
end

function NavMap:__construct()
	self.iw=0
	self.ih=0
    self.map = nil
    self.__grid={}
    self.spawners = {}
end

function NavMap:free()
    self.__grid = {}
    self.spawners = {}
end

function NavMap:load(map)
    self.map = map

    self.iw=map.iw
	self.ih=map.ih
    self.__grid = {}
    self.spawners = {}

    GAME.__dbg_segments = {}

    --=
    for iy=1, self.ih do
		self.__grid[iy]={}
		for ix=1, self.iw do
            self.__grid[iy][ix] = NavTile(ix, iy)
            assert(map.__grid[iy][ix], 'err:'..ix..' '..iy)
        end
    end
    --=
    for iy=1, self.ih do
		for ix=1, self.iw do
            self:seek_fall(ix, iy)
            self:seek_jump_edge(ix, iy)
            self:seek_jump_platf(ix, iy)
            self:seek_ladder_up(ix, iy)
            self:seek_ladder_down(ix, iy)
            self:seek_spawner(ix, iy)
        end
    end
end

function NavMap:seek_ground(ix, iy)
    local dist = 1

    while 1 do
        local tl = self.map:tile_at_index(ix, iy+dist)
        
        if not tl then
            return nil, nil, nil
        elseif tl.c_tile:has_prop(Tl.Prop.Ground) then
            return self:tile_at_index(tl.ix, tl.iy-1), dist, tl
        end

        dist = dist + 1
    end
end

-- function NavMap:validateAndInsertPlatfJump(nm_src, nm_dst, i, h)
--     local max_dist = Tl.Dim * 8--4.2
--     local in_range = max_dist >= nm_src.tl.c_b:dist_to(nm_dst.tl.c_b)
--     local max_h = 6

--     if in_range and h >= 1 and h <= max_h then
--         local type = NavAction.Type.Jump
--         -- = check segment collision with walls
--         local is_valid = true
--         GAME.bump_world:querySegment(nm_src.tl.c_b.x, nm_src.tl.c_b.y, nm_dst.tl.c_b.x, nm_dst.tl.c_b.y,
--             function(item)
--                 if Xtype.is(item, E_Tile) and item.c_tile:has_prop(Tl.Prop.Wall) then
--                     is_valid = false
--                 end
--             end
--         )
--         if is_valid then
--             -- print('inserting jump')
--             nm_src:insert_action(NavAction(type, nm_src, nm_dst, i), 1)
--             nm_dst:insert_action(NavAction(type, nm_dst, nm_src, -i), -1)
--         end
--     end
-- end

function NavMap:seek_jump_platf(ix, iy)
    local type = NavAction.Type.Jump

    local nm_src = self:tile_at_index(ix, iy)
    local nm_below = self:tile_at_index(ix, iy+1)

    if nm_below and nm_below.tl.c_tile:has_prop(Tl.Prop.Platform) then
        local max_w = 3

        for i=-max_w, max_w do
            for j=2, 6 do
                local e_tl = self.map:tile_at_index(ix+i, iy+j)
                local is_valid_dist = math.abs(i) * 0.5 + j <= 5

                if is_valid_dist and e_tl and e_tl.c_tile:isGround() then
                    -- GAME:debugDrawRect(e_tl.c_b.x, e_tl.c_b.y, Tl.Dim, Tl.Dim, {1, 0, 0, 0.5})
                    local nm_dst = self:tile_at_index(e_tl.ix, e_tl.iy-1)

                    if nm_src and nm_dst then
                        local is_valid = true
                        GAME.bump_world:querySegment(nm_src.tl.c_b.x, nm_src.tl.c_b.y, nm_dst.tl.c_b.x, nm_dst.tl.c_b.y,
                            function(item)
                                if Xtype.is(item, E_Tile) and item.c_tile:has_prop(Tl.Prop.Wall) then
                                    is_valid = false
                                end
                            end
                        )
                        if is_valid then
                            nm_src:insert_action(NavAction(type, nm_src, nm_dst, i), 1)
                            nm_dst:insert_action(NavAction(type, nm_dst, nm_src, -i), -1)
                        end
                    end
                end
            end
        end
    end
end

function NavMap:seek_fall(ix, iy)
    local nm_src = self:tile_at_index(ix, iy)
    local type = NavAction.Type.Fall
    -- = left
    if GAME.map:is_corner(ix, iy+1, 1) then 
        local nm_dst, dist = self:seek_ground(ix-1, iy)
        if nm_dst then
            nm_src:insert_action(NavAction(type, nm_src, nm_dst, -1), 1)
        end
    end
    -- = right
    if GAME.map:is_corner(ix, iy+1, -1) then
        local nm_dst, dist = self:seek_ground(ix+1, iy)
        if nm_dst then
            nm_src:insert_action(NavAction(type, nm_src, nm_dst, 1), 1)
        end
    end
end

function NavMap:seek_jump_targets(nm_src, ix, iy)
    local type = NavAction.Type.Jump
    local max_h = 5
    local nm_dst, h = self:seek_ground(ix, iy)
    local max_dist = 7

    if nm_src and nm_dst then
        local iw_dist = math.abs(nm_src.tl.ix - nm_dst.tl.ix)
        local in_range = h + iw_dist < max_dist
        if in_range and h and h >= 2 and h <= max_h then
            nm_src:insert_action(NavAction(type, nm_src, nm_dst, -1),  1)
            nm_dst:insert_action(NavAction(type, nm_dst, nm_src,  1), -1)
        end
    end
end

function NavMap:seek_jump_edge(ix, iy)

    local max_w = 3
    local is_edge_left = self:isEdge(ix, iy+1, 1)
    local is_edge_right = self:isEdge(ix, iy+1, -1)

    if is_edge_left then
        for i=0, 1 do
            local is_ground = GAME.map:isGroundAtIndex(ix+i, iy+1)
            local nm_src = self:tile_at_index(ix+i, iy)
            for j=1, max_w do
                if is_ground then
                    self:seek_jump_targets(nm_src, ix-j, iy)
                end
            end
        end
    end

    if is_edge_right then
        for i=0, 1 do
            local is_ground = GAME.map:isGroundAtIndex(ix-i, iy+1)
            local nm_src = self:tile_at_index(ix-i, iy)
            for j=1, max_w do
                if is_ground then
                    self:seek_jump_targets(nm_src, ix+j, iy)
                end
            end
        end
    end
end

function NavMap:seek_ladder_up(ix, iy)
    local tl = self.map:tile_at_index(ix, iy)
    local type = NavAction.Type.Ladder

    if tl and tl.c_tile:has_prop(Tl.Prop.Ladder) then
        local tl_below = self.map:tile_at_index(ix, iy+1)

        if tl_below and tl_below.c_tile:has_prop(Tl.Prop.Ground) then
            local nm_src = self:tile_at_index(ix,iy)
            nm_src:insert_action(NavAction(type, tl, nil), -1)
            -- table.insert(self:tile_at_index(ix,iy).up, NavAction(NavAction.Type.Ladder, tl, nil))
        end
    end
end

function NavMap:seek_ladder_down(ix, iy)
    local tl = self.map:tile_at_index(ix, iy)
    local tl_below = self.map:tile_at_index(ix, iy+1)
    local type = NavAction.Type.Ladder

    if tl and tl.c_tile:has_prop(Tl.Prop.Empty) and tl_below and tl_below.c_tile:has_prop(Tl.Prop.Ladder) then
        local nm_src = self:tile_at_index(ix,iy)
        nm_src:insert_action(NavAction(type, tl, nil), 1)
        --  table.insert(self:tile_at_index(ix,iy).down, NavAction(NavAction.Type.Ladder, self.map:tile_at_index(ix, iy), nil))
    end
end

function NavMap:evaluate_tile(ix, iy)
    self:seek_fall(ix, iy)
    self:seek_jump_edge(ix, iy)
    self:seek_jump_platf(ix, iy)
    self:seek_ladder_up(ix, iy)
    self:seek_ladder_down(ix, iy)
end


function NavMap:destroy_tile(ix, iy, recursion_i)
    local tl = self:tile_at_index(ix, iy)
    local tl_above = self:tile_at_index(ix, iy-1)

    if tl_above then
        -- print('=>', #tl_above.from)
        for _, from in ipairs(tl_above.from) do

            from.down = table.filter(from.down, function(navact, i)
                -- print('=>', 'donw')
                -- print(from.nava)
                if navact.dest == tl_above then
                    -- print('=>', 'donw')
                end
                return navact.dest ~= tl_above
            end)

            from.up = table.filter(from.up, function(navact, i)
                -- print('=>', 'up')
                if navact.dest == tl_above then
                    from.up[i] = nil
                    -- print('=>', 'up')
                end
                return navact.dest ~= tl_above
            end)
        end

        tl_above.down = {}
        tl_above.up = {}
    end

    

    self.__grid[iy][ix] = NavTile(ix, iy)
    self:evaluate_tile(ix, iy)
    self:evaluate_tile(ix-1, iy)
    self:evaluate_tile(ix+1, iy)
    -- self:evaluate_tile(ix, iy-1)
end

-- function NavMap:destroy_tile(ix, iy, recursion_i)
--     local nv_tl = self:tile_at_index(ix, iy)
--     local nv_tl_above = self:tile_at_index(ix, iy-1)

--     recursion_i = recursion_i or 1

--     if nv_tl_above then
--         for i, navact_from in ipairs(nv_tl_above.from) do

--             for i, navact in ipairs(navact_from.up) do
--                 if navact.dest == nv_tl_above then
--                     table.remove(navact_from.up, i)
--                 end
--             end
    
--             for i, navact in ipairs(navact_from.down) do
--                 if navact.dest == nv_tl.tl then
--                     table.remove(navact_from.down, i)
--                 end
--             end
--         end
--     end
   

--     if nv_tl_above then
--         nv_tl_above.up = {}
--         nv_tl_above.down = {}
--     end

--     self.__grid[iy][ix] = NavTile(ix, iy)

--     self:evaluate_tile(ix-1, iy-1)
--     self:evaluate_tile(ix+1, iy-1)
-- end

function NavMap:seek_spawner(ix, iy)
    local tl = self.map:tile_at_index(ix, iy)

    if tl and tl.c_tile:has_prop(Tl.Prop.Empty) then
        local tl_bot = self.map:tile_at_index(ix, iy+1)

        if tl_bot and tl_bot.c_tile:has_prop(Tl.Prop.Ground) then
            table.insert( self.spawners, tl )
        end
    end
end

function NavMap:is_index_valid(ix, iy)
    return ix>0 and iy>0 and ix<=self.iw and iy<=self.ih
end

function NavMap:tile_at_index(ix, iy)
    return self:is_index_valid(ix, iy) and self.__grid[iy][ix] or nil
end

function NavMap:tile_at(x, y)
    local ix, iy = self:to_index(x, y)
    return self:tile_at_index(ix, iy)
end

function NavMap:to_index(x, y)
    return math.ceil((x-GAME.map.x) / Tl.Dim), math.ceil((self.map.h+y) / Tl.Dim)
end

function NavMap:isEdge(ix, iy, dir) -- = dir=1 or -1
    local t = self.map:tile_at_index(ix, iy)
    local t_b = self.map:tile_at_index(ix-dir, iy)
    local t_u = self.map:tile_at_index(ix, iy-1)
    local t_bu = self.map:tile_at_index(ix-dir, iy-1)

    if not t then
        return false
    end
    local ix_outbound = (dir == 1 and ix-1 < 1) or (dir == -1 and ix+1 > self.map.iw)
    if (
        t.c_tile:has_prop(Tl.Prop.Ground) and
        ( ix_outbound or t_b.c_tile:has_prop(Tl.Prop.Empty) ) and--or t_b.c_tile:has_prop(Tl.Prop.Ladder) ) and 
        ( ix_outbound or t_u.c_tile:has_prop(Tl.Prop.Empty) ) and--or t_u.c_tile:has_prop(Tl.Prop.Ladder) ) and
        ( ix_outbound or t_bu.c_tile:has_prop(Tl.Prop.Empty) )--or t_bu.c_tile:has_prop(Tl.Prop.Ladder) )
    ) then
        return true
    end
    return false
end

function NavMap:drawFallAct(ix, iy, nv_act)

    love.graphics.circle('fill', GAME.map.x+(ix-.5) * Tl.Dim, GAME.map.y+(iy-.5) * Tl.Dim, Tl.Dim * 0.1)
    -- lines
    local hdir = nv_act.dir
    local x = hdir == 1 and ix+1 or ix-1
    local y1 = (nv_act.src.tl.iy-.5) * Tl.Dim
    local y2 = (nv_act.dest.tl.iy-.5) * Tl.Dim
    -- horizontal line
    love.graphics.line(
        GAME.map.x+(ix-.5)*Tl.Dim,
        GAME.map.y+y1,
        GAME.map.x+(x-.5)*Tl.Dim,
        GAME.map.y+y1
    )
    -- vertical line
    love.graphics.line(
        GAME.map.x+(x-.5)*Tl.Dim,
        GAME.map.y+y1,
        GAME.map.x+(x-.5)*Tl.Dim,
        GAME.map.y+y2
    )
end

function NavMap:drawJumpAct(ix, iy, nv_act)
    love.graphics.line(
        GAME.map.x+(nv_act.src.tl.ix-.5)*Tl.Dim,
        GAME.map.y+(nv_act.src.tl.iy-.5)*Tl.Dim,
        GAME.map.x+(nv_act.dest.tl.ix-.5)*Tl.Dim,
        GAME.map.y+(nv_act.dest.tl.iy-.5)*Tl.Dim
    )
end

function NavMap:drawNavAction(ix, iy, nv_act)
    local alpha = 0.5
    local colors = {}
    colors[NavAction.Type.Fall] = {1, 0, 1, 0.5}
    colors[NavAction.Type.Jump] = {0, 1, 0, 0.2}
    colors[NavAction.Type.Ladder] = {0, 0, 1, alpha}
    colors[NavAction.Type.Ladder] = {1, 0, 1, alpha}
    local color = colors[nv_act.type]
    love.graphics.setColor(unpack(color))

    if (nv_act.type == NavAction.Type.Fall) then
        self:drawFallAct(ix, iy, nv_act)
    elseif (nv_act.type == NavAction.Type.Jump)  then
        self:drawJumpAct(ix, iy, nv_act)
    end
end

function NavMap:draw()
    if not DEBUG_NAVMAP then
        return
    end
    for iy=1, self.ih do
		for ix=1, self.iw do
			local nv_tl=self.__grid[iy][ix]
			if nv_tl then
                for i, nv_act in ipairs(nv_tl.up) do
                    self:drawNavAction(ix, iy, nv_act)
                end
                for i, nv_act in ipairs(nv_tl.down) do
                    self:drawNavAction(ix, iy, nv_act)
                end
			end
		end
	end
    love.graphics.setColor({1, 1, 1})
end

return NavMap, NavAction, NavTile

