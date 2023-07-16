local Map=Class('Map')

--= Tl <=> TiLe
Tl={}
Tl.Type={Err=1,Empty=2,Wall=3,Platform=4,LadW=5,Lad=6}
Tl.Prop={Ground=1,Ceil=2,Platform=4,Ladder=8,Wall=16, Empty=32, Edge_Left=64, Corner_Left=128, Edge_Right=256, Corner_Right=512}
Tl.Dim=32

function Map:__construct()
    self.x=0
	self.y=0
	self.iw=0
	self.ih=0
    self.w=0
    self.h=0
    self.is_loaded = false

    self.__grid={}
    --= tileset
    self.__px_lvl = nil
    self.__px_ref = love.image.newImageData('asset/map/px-tileset.png')

    self.__tileset=love.graphics.newImage('asset/tileset-judo-commando.png')
    self.__tileset_building=love.graphics.newImage('asset/tileset-building-out.png')
    self.__tileset_quads={} 
    for i=0, self.__px_ref:getWidth()-1 do
		self.__tileset_quads[i+1]=love.graphics.newQuad(i*Tl.Dim, 0, Tl.Dim, Tl.Dim, self.__tileset:getDimensions())
	end

    self.__tileset_background = love.graphics.newImage('asset/background-tileset.png')
    self.__tileset_background_quads = {}
    for i=0, self.__tileset_background:getWidth()/20-1 do
        self.__tileset_background_quads[i+1]=love.graphics.newQuad(i*20, 0, 20, 20, self.__tileset_background:getDimensions())
    end
    
    self.__tileset_building_quads={}
    self.__tileset_building_quads[1]=love.graphics.newQuad(0, 0, Tl.Dim, Tl.Dim, self.__tileset_building:getDimensions())
    self.__tileset_building_quads[2]=love.graphics.newQuad(32, 0, Tl.Dim, Tl.Dim, self.__tileset_building:getDimensions())

    --= nouveau systeme de quads
    self.__quads = {}
    for k, type in pairs(Tl.Type) do
        self.__quads[type] = {}
    end
    
    for i=1, 9  do -- indoor walls
		self.__quads[Tl.Type.Wall][i]=love.graphics.newQuad((i-1)*Tl.Dim, Tl.Dim, Tl.Dim, Tl.Dim, self.__tileset:getDimensions())
	end

    for i=1, 9  do -- outdoor walls
		self.__quads[Tl.Type.Wall][i]=love.graphics.newQuad((i-1)*Tl.Dim, Tl.Dim, Tl.Dim, Tl.Dim, self.__tileset:getDimensions())
	end

    for i=1, 11 do --= indoor backgrounds
		self.__quads[Tl.Type.Empty][i]=love.graphics.newQuad((i-1)*Tl.Dim, Tl.Dim*3, Tl.Dim, Tl.Dim, self.__tileset:getDimensions())
	end

    --= window
    self.__win_img = love.graphics.newImage('asset/building-window.png')
    self.__win_quad = love.graphics.newQuad(0, 0, 52, 72+8, self.__win_img:getDimensions())
    -- self.__win_ornament_quads = {}
    -- for i=1, 3 do
    --     self.__win_ornament_quads[i] = love.graphics.newQuad(0, 72, 52, (i-1 * 8), self.__win_img:getDimensions())
    -- end

    self.background_grid = {}
end

function Map:loadBackground()
    local iw = math.ceil(self.w / 20)
    local ih = math.ceil(self.h / 20)

    self.background_grid = {}
    local a = self.w % 20 - 2
    self.__tileset_background_quads[2] = love.graphics.newQuad(40, 0, a, 20, self.__tileset_background:getDimensions())

    for iy=1, ih do
        self.background_grid[iy]={}
		for ix=1, iw do
            local quad_i = nil
            local is_variant = math.random(100) >= 90
            if ix == 1 then
                quad_i = 1
            elseif ix == iw then
                quad_i = 2
            elseif is_variant then
                quad_i = math.random(4, #self.__tileset_background_quads)
            else
                quad_i = 3
            end
            self.background_grid[iy][ix] = quad_i
        end
	end
end

function Map:load(id, x)
    self.__px_lvl = love.image.newImageData('asset/map/'..id..'.png')

    self.iw=self.__px_lvl:getWidth()
	self.ih=self.__px_lvl:getHeight()
    self.w=self.iw * Tl.Dim
    self.h=self.ih * Tl.Dim
    self.x = x or 0
    self.y = 0 - self.h
    --=
	for y=1, self.ih do
		self.__grid[y]={}
		for x=1, self.iw do
            local map_r, map_g, map_b = self.__px_lvl:getPixel(x-1, y-1)
            for tile_type=1, self.__px_ref:getWidth() do
                local ref_r, ref_g, ref_b = self.__px_ref:getPixel(tile_type-1, 0)

                if map_r == ref_r and map_g == ref_g and map_b == ref_b then
                    local e_tl = E_Tile(self.x, self.y, x, y, tile_type)
                    self.__grid[y][x]= e_tl
					break
				end
			end
            assert(self.__grid[y][x] ~= nil)
		end
	end

    for iy=1, self.ih do
		for ix=1, self.iw do
            self:eval_edge_at(ix, iy)
        end
    end
    self.is_loaded = true
    self:loadBackground()
end

function Map:eval_edge_at(ix, iy)

    if not self:is_index_valid(ix, iy) then
        return
    end

    local e_tl = self.__grid[iy][ix]
    local c_tl = e_tl.c_tile

    if self:isEdge(ix, iy, 1) then
        c_tl.props = c_tl.props + Tl.Prop.Edge_Right
    end
    if self:isEdge(ix, iy, -1) then
        c_tl.props = c_tl.props + Tl.Prop.Edge_Left
    end
    
    if self:is_corner(ix, iy, 1) then
        c_tl.props = c_tl.props + Tl.Prop.Corner_Right
    end

    if self:is_corner(ix, iy, -1) then
        c_tl.props = c_tl.props + Tl.Prop.Corner_Left
    end
end

function Map:get_tile_properties(ix, iy, type)
    local t = type
    local p = 0

    if t==Tl.Type.Empty then
        p=p+Tl.Prop.Empty
    end
    if t==Tl.Type.Wall or t==Tl.Type.LadW or t==Tl.Type.Platform then
        -- local e_tl_up = self:tile_at_index(ix, iy-1)
        -- if e_tl_up ~= nil and e_tl_up.c_tile.type == Tl.Type.Empty then
        p=p+Tl.Prop.Ground
        -- end
    end
    if t==Tl.Type.Wall or t==Tl.Type.LadW then
        p=p+Tl.Prop.Ceil
    end
    if t==Tl.Type.Platform then
        p=p+Tl.Prop.Platform
    end
    if t==Tl.Type.LadW or t==Tl.Type.Lad then
        p=p+Tl.Prop.Ladder
    end
    if t==Tl.Type.LadW or t==Tl.Type.Wall then
        p=p+Tl.Prop.Wall
    end

    return p
end

function Map:draw_building(start_draw_y, ih)
    --= walls
    for iy=1, ih do
		for ix=1, self.iw do
            local quad=nil
            if i == 1 then 
                quad = self.__tileset_building_quads[1]
            else
                quad = self.__tileset_building_quads[2]
            end
            love.graphics.draw(self.__tileset_building, quad, self.x+(ix-1) * Tl.Dim, start_draw_y + (iy-1) * Tl.Dim)
        end
    end

    -- windows
    local win_img_w = self.__win_img:getWidth()
    local win_img_h = 72 --self.__win_img:getHeight()

    local pad_x = 40
    local pad_y = 16
    
    local win_span_w_ratio = 2
    local win_span_h_ratio = 1.5

    local tot_span_w = self.w - (pad_x * 2)
    local tot_span_h = ih * Tl.Dim - (pad_y * 2)

    local win_span_w = (win_img_w * win_span_w_ratio)
    local win_span_h = (win_img_h * win_span_h_ratio)

    local win_iw, tot_span_excess_w = math.modf(tot_span_w / win_span_w)
    local win_ih, tot_span_excess_h = math.modf(tot_span_h / win_span_h)

    win_iw = math.floor(win_iw)-1
    win_ih = math.floor(win_ih)-1

    --= adjust building padding
    pad_x = pad_x + win_span_w * tot_span_excess_w * 0.5
    pad_y = pad_y + win_span_h * tot_span_excess_h * 0.5
    love.graphics.setColor(GAME.draw_color.bg)
    for ix=0, win_iw do
        for iy=0, win_ih do
            local x = self.x + pad_x + (ix * win_span_w) + (win_span_w * 0.5) - (win_img_w * 0.5)
            local y = start_draw_y + pad_y + (iy * win_span_h) + (win_span_h * 0.5) - (win_img_h * 0.5)
            love.graphics.draw(self.__win_img, self.__win_quad, x, y)
        end
    end
end

function Map:drawBackground()
    local iw = math.ceil(self.w / 20)
    local ih = math.ceil(self.h / 20)

    local tileset = self.__tileset_background

    for iy=1, ih do
		for ix=1, iw do
            local quad_i=self.background_grid[iy][ix]
            local quad=self.__tileset_background_quads[quad_i]

            love.graphics.draw(tileset, quad, self.x+(ix-1)*20, self.y+(iy-1)*20)
        end
	end
end

function Map:draw()
    local building_left = self.x
    local building_top_h = 20
    local building_top_y = self.y - building_top_h * Tl.Dim
    -- local
    if (GAME.e_hero.c_state_machine:is(St_GoNextLvl) and (GAME.e_hero.c_b:right() < self.x or GAME.e_hero.c_b:left() > self.x + self.w)) then
        building_top_h = building_top_h + self.h
    end

    love.graphics.setColor(GAME and GAME.draw_color.bg or {1,1,1,1})
    self:drawBackground()
    love.graphics.setColor(GAME and GAME.draw_color.map or {1,1,1,1})
    for iy=1, self.ih do
		for ix=1, self.iw do
			local e_tl=self.__grid[iy][ix]
			if e_tl and e_tl.type~=Tl.Type.Empty then
                local c_tl=e_tl.c_tile
				local quad=e_tl.quad
                if not quad then
				    quad=self.__tileset_quads[c_tl.type]
                end
                if quad then
                    -- if c_tl.highlight_color then
                    --     love.graphics.setColor(c_tl.highlight_color)
                    -- end
                    love.graphics.draw(self.__tileset, quad, self.x +(ix-1) * Tl.Dim, self.y + (iy-1) * Tl.Dim)
                end
			end
		end
	end
    love.graphics.setColor(GAME and GAME.draw_color.bg or {1,1,1,1})
    self:draw_building(building_top_y, building_top_h)

    local building_bot_h = 31
    local building_bot_y = self.y + self.h - Tl.Dim * 2

    self:draw_building(building_bot_y, building_bot_h)
end

function Map:unload()
    self.is_loaded = false
    for iy=1, self.ih do
		for ix=1, self.iw do
			local e_tl=self.__grid[iy][ix]
			if e_tl then
                GAME:del_e(e_tl)
            end
        end
    end
end

function Map:tile_at_index(ix, iy)
    return self:is_index_valid(ix, iy) and self.__grid[iy][ix] or nil
end

function Map:tile_at(x, y)
    return self:tile_at_index(self:to_index(x, y))
end

function Map:to_index(x, y)
    local ix, iy = nil, nil
    
    if x ~= nil then
        ix = math.ceil((x-self.x) / Tl.Dim)
    end
    if y ~= nil then
        iy = math.ceil((self.h+y) / Tl.Dim)
    end
    return ix, iy
end

function Map:is_index_valid(ix, iy)
    return ix>0 and iy>0 and ix<=self.iw and iy<=self.ih
end

function Map:neighbor(tl, dx, dy)
    self:tile_at_index(tl.ix+dx, tl.iy+dy)
end

function Map:is_corner(ix, iy, dir) --= dir=1 or -1
    local t = self:tile_at_index(ix, iy)
    local t_bk = self:tile_at_index(ix-dir, iy)
    local t_up = self:tile_at_index(ix, iy-1)
    local t_bkup = self:tile_at_index(ix-dir, iy-1)

    if not t or not t_up then
        return false
    end

    if (
        t.c_tile:has_prop(Tl.Prop.Wall) and
        ( t_bk == nil or t_bk.c_tile:has_prop(Tl.Prop.Empty) )and--or t_bk.c_tile:has_prop(Tl.Prop.Ladder) ) and 
        ( t_up.c_tile:has_prop(Tl.Prop.Empty) )and--or t_up.c_tile:has_prop(Tl.Prop.Ladder) ) and
        ( t_bkup == nil or t_bkup.c_tile:has_prop(Tl.Prop.Empty) )--or t_bkup.c_tile:has_prop(Tl.Prop.Ladder) )
    ) then
        return true
    end
    
    return false
end

function Map:isEdge(ix, iy, dx) --= dir=1 or -1
    local tl_mid = self:tile_at_index(ix, iy)


    -- if not tl_mid then
    --     return false
    -- end

    -- local c_mid = tl_mid.c_tile

    -- if not c_mid:has_prop(Tl.Prop.Ground) then
    --     return false
    -- end
    -- local neighbors = {
    --     up = c_mid:neighbor(0, -1),
    --     lat = c_mid:neighbor(dx, 0),
    --     let_up = c_mid:neighbor(dx, -1)
    -- }

    -- for k, neighbor in pairs(neighbors) do
    --     if neighbor and not neighbor.c_tile:has_prop(Tl.Prop.Empty) then

    --         return false
    --     end
    -- end

    return true
end

function Map:destroy_tile(ix, iy, normal_x)
    if not self:is_index_valid(ix, iy) then
        return
    end
    if (iy < 3 or iy > self.ih-3) then
        return
    end

    local e_tl = self.__grid[iy][ix]

    if e_tl.c_tile:has_prop(Tl.Prop.Ladder) then -- or e_tl.c_tile:has_prop(Tl.Prop.Platform) then
        return
    end

    if e_tl.c_tile:isPlatform() then
        GAME.cam:shake(0.05, 6)
    end

    local ng_r = e_tl.c_tile:neighbor(1, 0)
    local ng_l = e_tl.c_tile:neighbor(-1, 0)
    local ng_d = e_tl.c_tile:neighbor(0, 1)

    GAME:del_e(e_tl)
    GAME:emit_debris(e_tl.c_b:mid_x(), e_tl.c_b:mid_y(), normal_x)

    self.__grid[iy][ix] = E_Tile(self.x, self.y, ix, iy, Tl.Type.Empty)
    if ng_l then
        self:eval_edge_at(ng_l.ix, ng_l.iy)
    end
    if ng_r then
        self:eval_edge_at(ng_r.ix, ng_r.iy)
    end
    if ng_d then
        self:eval_edge_at(ng_d.ix, ng_d.iy)
    end

    GAME.navmap:destroy_tile(ix, iy)
end

function Map:isSolidAt(x, y)
    local tl = self:tile_at(x, y)
    if tl then
        return tl.c_tile:has_prop(Tl.Prop.Wall)
    end
    return false
end

function Map:isSolidAtIndex(ix, iy)
    local tl = self:tile_at_index(ix, iy)
    return tl and tl.c_tile:has_prop(Tl.Prop.Wall)
end

function Map:isGroundAtIndex(ix, iy)
    local e_tl = self:tile_at_index(ix, iy)
    local e_tl_up = self:tile_at_index(ix, iy-1)
    return e_tl and e_tl.c_tile:has_prop(Tl.Prop.Ground) and (not e_tl_up or not e_tl_up.c_tile:has_prop(Tl.Prop.Ground))
end

function Map:getNextGroundTile(ix, iy)
    local cur = nil
    local bot = nil
    repeat
        bot = self:tile_at_index(ix, iy)

        if bot and cur and bot.c_tile:has_prop(Tl.Prop.Ground) then
            return cur
        end
        cur = bot
        iy = iy + 1
    until cur == nil
    return nil
end

function Map:getNextCeilTile(ix, iy)
    local cur = nil
    local bot = nil
    repeat
        bot = self:tile_at_index(ix, iy)

        if bot and cur and bot.c_tile:has_prop(Tl.Prop.Wall) then
            return cur
        end
        cur = bot
        iy = iy - 1
    until cur == nil
    return nil
end

function Map:cooToIndex(x, y)
    local ix, iy = nil, nil
    if x then
        ix = math.ceil((x-self.x) / Tl.Dim)
    end
    if y then
        iy = math.ceil((self.h+y) / Tl.Dim)
    end
    
    return ix, iy
end

return Map