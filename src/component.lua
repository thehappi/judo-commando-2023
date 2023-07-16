local Bit = Bit or require("bit")

Comp=Class('Comp')

function Comp:__construct(e)
    self.active=true
    self.e=e
    --=
    self.on_off = nil -- callback
end

function Comp:on()
    self.active=true;
    return self
end

function Comp:off()
    self.active=false;
    if self.on_off then self:on_off() end
    return self
end

function Comp:is_on()
    return self.active
end

function Comp:preset(key_value_table) -- key_value
    for k,v in pairs(key_value_table) do
        if self[k] ~= nil then
            self[k]=v
        end
    end
    
end

--===========================#
--

C_Tile=Class('C_Tile', Comp)

function C_Tile:__construct(e, ix, iy, type, props)
    Comp.__construct(self, e)
    --=
    self.props=props or 0
    self.index = V2(ix,iy)
    self.type=type
    self.highlight_color=nil
end

function C_Tile:has_prop(property)
    return Bit.band(self.props, property) == property
end

function C_Tile:has_all_props(...)
    for _, property in ipairs({...}) do
        if not self:has_prop(property) then
            return false
        end
    end
    return true
end

function C_Tile:has_only_props(...)
    local n=self.props
    for _, property in ipairs({...}) do
        n=n-Bit.band(self.props, property)
    end
    return n==0
end

function C_Tile:has_at_min_one_prop(...)
    local n=self.props
    for _, property in ipairs({...}) do
        if Bit.band(self.props, property) then
            return true
        end
    end
    return false
end

function C_Tile:neighbor(vx, vy)
    return GAME.map:tile_at_index(self.index.x+vx, self.index.y+vy)
end

function C_Tile:isEdge(dir)
    return GAME.map:is_corner(self.index.x, self.index.y, dir)
end

function C_Tile:isGround()
    local e_tl_up = self:neighbor(0, -1)
    return self:isSolid() or self:isPlatform()
        and e_tl_up and e_tl_up.c_tile:isEmpty()
end

function C_Tile:isEmpty()
    return self:has_prop(Tl.Prop.Empty)
end

function C_Tile:isSolid()
    return self:has_prop(Tl.Prop.Wall)
end

function C_Tile:isPlatform()
    return self:has_prop(Tl.Prop.Platform)
end

function C_Tile:isEmptyBelow()
    local e_below = self:neighbor(0, 1) 
    return e_below and e_below.c_tile:isEmpty()
end

--===========================#
--

C_Gravity=Class('C_Gravity', Comp)

function C_Gravity:__construct(e)
    Comp.__construct(self, e)
    --=
    self.acc=Tl.Dim*30
    self.min=0
    self.max=Tl.Dim*13
end

-- function C_Gravity:on_off()
    -- self.e.c_b.vy=0
-- end


--===========================#
--

C_MoveHrz=Class('C_MoveHrz', Comp)

function C_MoveHrz:__construct(e)
    Comp.__construct(self, e)
    --=
    self.acc = 228*70
    self.dec = Tl.Dim*40
    self.max = 228
    self.min = Tl.Dim*1
end

function C_MoveHrz:on_off()
    self.e.c_b.vx=0
end

--===========================#
--

C_MoveVert=Class('C_MoveVert', Comp)

function C_MoveVert:__construct(e)
    Comp.__construct(self, e)
    --=
    -- self.acc = Tl.Dim*70
    -- self.dec = Tl.Dim*40
    -- self.max = Tl.Dim*5
    -- self.min = Tl.Dim*1
end

--===========================#
--

C_Pad=Class('C_Pad', Comp)

function C_Pad:__construct(e, listen_to_keyboard)
    Comp.__construct(self, e)
    --=
    self.__keys = {}
    self.__oldkeys = {}
    --=
    --=
    self.listen_to_keyboard = listen_to_keyboard == nil and true or listen_to_keyboard
end

function C_Pad:add_key(game_keyname, love_keyname)
    love_keyname = love_keyname or game_keyname
    self.__keys[game_keyname] = {
        love_keyname=love_keyname,
        is_pressed=false,
        is_pressed_once=false,
        is_released=false,
        is_released_once=false,
        time_pressed=0,
        time_pressed_once=0,
        oldpad=false,
        pressed_at=0,
        released_at=0,
    }
    self.__oldkeys[game_keyname] = {
        is_pressed=false,
    }
end

function C_Pad:is_pressed(game_keyname)
    local k = self.__keys[game_keyname]
    return k and k.is_pressed
end

function C_Pad:is_pressed_once(game_keyname, delay)
    local k = self.__keys[game_keyname]
    local oldk = self.__oldkeys[game_keyname]

    return (k.is_pressed and not oldk.is_pressed)
        or (delay and k.is_pressed and k.time_pressed <= delay)
end

function C_Pad:is_pressed2(game_keyname, delay)
    local k = self.__keys[game_keyname]
    local oldk = self.__oldkeys[game_keyname]

    return (delay and k.is_released and k.time_pressed <= delay)
        -- (k.time_pressed > delay)
end

-- function C_Pad:is_pressed_once2(game_keyname, delay)
--     -- local once = self.__keys[game_keyname].is_pressed and not self.__oldkeys[game_keyname].is_pressed
--     local k = self.__keys[game_keyname]
--     local oldk = self.__oldkeys[game_keyname]

--     return (not k.is_pressed and oldk.is_pressed) or (delay and k.is_pressed and k.time_pressed <= delay)
-- end

function C_Pad:press(game_keyname) -- manual mode for AI
    if self.__keys[game_keyname] then
        self.__keys[game_keyname].is_pressed = true
    end
end

function C_Pad:clear()
    for _, key_props in pairs(self.__keys) do
        key_props.is_pressed = false
    end
end

function C_Pad:get(game_keyname)
    return self.__keys[game_keyname]
end

--===========================#
--

C_Anim=Class('C_Anim', Comp)

function C_Anim:__construct(e, atlas)
    Comp.__construct(self, e)
    --=
    self.atlas=atlas
    self.props=nil
    self.timer=0
    self.ox=0.5 -- ratio
    self.oy=1 -- ratio
    self.dir=-1 -- 1 or -1
    self.is_over=false
    self.is_paused=false
    self.frame_i=1
    self.cur_key=nil
    self.duration=1
    self.enter_frame = false
    self.is_blinking = false
    self.r = 0
    return self
end

function C_Anim:set(name, ox, oy)
    if name and self.atlas[name] == self.props then
        return self
    end
    self.cur_key = name
    self.props=self.atlas[name]
    self.ox=ox or 0.5
    self.oy=oy or 1
    self.is_over=false
    self.timer=0
    self.is_paused=false
    self.enter_frame = false
    self.frame_i=nil
    if self.props then
        self.duration = self.props.duration
    end
    -- if self.props and self.props.__pause then
        -- self:pause()
        -- self.timer = 100
    -- end
    return self
end

-- function c_anim:replace_spritesheet(find, replace)
    
-- end

function C_Anim:set_origin(ox, oy)
    self.ox = ox and ox or self.ox
    self.oy = oy and oy or self.oy
end

function C_Anim:pause()
    self.is_paused=true
end

function C_Anim:play()
    self.is_paused=false
end

function C_Anim:stop()
    self.is_paused=true
end


function C_Anim:set_frame(frame_index)
    self.timer = self.props.duration / #self.props.frames * (frame_index-1) + 0.01
end

function C_Anim:get_frame()
    return self.frame_i
    -- self.timer = self.props.duration / #self.props.frames * (frame_index-1) + 0.01
end

function C_Anim:reset(frame_i)
    frame_i = frame_i or nil
    self.ox=ox or 0.5
    self.oy=oy or 1
    self.is_over=false
    self.timer=0
    self.is_paused=false
    self.enter_frame = false
    self.frame_i=frame_i
    -- self.is_blinking = false
    self.is_over = false
    if self.props then
        self.duration = self.props.duration        
    end
end

function C_Anim:is(name)
    return self.cur_key == name
end

function C_Anim:get_progress_as_percent()
    return self.timer / self.duration * 100
end

function C_Anim:blink(interval)
    self.blink_interval = interval
    self.blink_timer = 0
    self.blink_visible = false
    self.is_blinking = true
end


--===========================#
--

C_AnimDir=Class('C_AnimDir', Comp)

function C_AnimDir:__construct(e, atlas)
    Comp.__construct(self, e)
    --=
end

--===========================#
--

C_EventListener=Class('C_EventListener', Comp)

function C_EventListener:__construct(e)
    Comp.__construct(self, e)
    --=
    self.__signals = {}
end

function C_EventListener:once(signal_str, callback)
    self.__signals[signal_str] = {fn=callback, type='once'}
    local this = nil
    this = function (...)
        self.__signals[signal_str].fn(...)
        self.__signals[signal_str] = nil
        Signal.remove(signal_str, callback)
        Signal.remove(signal_str, this)
    end
    Signal.register(signal_str, this)
end

function C_EventListener:on(signal_str, callback)
    self.__signals[signal_str] = {fn=callback, type='on'}
end

--===========================#
--

C_Projectile=Class('C_Projectile', Comp)

function C_Projectile:__construct(e, dir_x, dir_y, speed, v2_pow, on_hit_spawn_e, e_owner)
    Comp.__construct(self, e)
    --=
    self.dir_x = dir_x
    self.dir_y = dir_y
    self.speed = speed
    self.spawn_e = on_hit_spawn_e
    self.pow_x = v2_pow.x
    self.pow_y = v2_pow.y
    self.dist_x = 0
    self.e_owner = e_owner
    --=
    e.c_anim.dir = dir_x
    e.c_b.vx = dir_x * speed
    e.c_b.vy = dir_y * speed
end

--===========================#
--

C_DelOnAnimOver=Class('C_DelOnAnimOver', Comp)

function C_DelOnAnimOver:__construct(e, dir_x)
    Comp.__construct(self, e)
    --=
end

--===========================#
--

C_FxTrail=Class('C_FxTrail', Comp)

function C_FxTrail:__construct(e, dir_x, E_FxClass, time_interval)
    Comp.__construct(self, e)
    --=
    self.e_fx = E_FxClass
    self.timer = 0
    self.time_interval = time_interval
    self.dir_x=dir_x
    self.dir_y = 1
end

--===========================#
--

C_ExplosionParticuleEmitter=Class('C_ExplosionParticuleEmitter', Comp)

function C_ExplosionParticuleEmitter:__construct(e, dir_x, E_FxClass, time_interval)
    Comp.__construct(self, e)
    --=
    -- self.e_fx = E_FxClass
    -- self.timer = 0
    -- self.time_interval = time_interval
    -- self.dir_x=dir_x
end

--===========================#
--

C_Health = Class('C_Health', Comp)

function C_Health:__construct(e, max)
    Comp.__construct(self, e)
    --=
    self.max = max
    self.hp = max or 0
end

function C_Health:get_hit(damages)
    self.hp = self.hp - damages
    if self.hp < 0 then
        self.hp = 0
    end
end

function C_Health:heal(hp)
    self.hp = self.hp + hp
    if self.hp > self.max then
        self.hp = self.max
    end
end

--===========================#
--

C_Blink = Class('C_Blink', Comp)

function C_Blink:__construct(e, hertz)
    Comp.__construct(self, e)
    --=
    self.timer = 0
    self.hertz = hertz or 0.18
    self.is_switch_on = true
end

--===========================#
--

C_Text = Class('C_Text', Comp)

function C_Text:__construct(e, text)
    Comp.__construct(self, e)
    --=
    self.text = text
    self.timer = 0
    self.blink_at = 0.3
    self.erase_at = 0.3
    self.o_text = love.graphics.newText( GAME.game_ui.font_score, text )
end

--===========================#
--

C_Jewel = Class('C_Jewel', Comp)

function C_Jewel:__construct(e, color)
    Comp.__construct(self, e)
    --=
    self.timer = 0
    self.blink_at = 5
    self.erase_at = self.blink_at + 0.4
    self.timer2 = 0
    self.color = color
    self.loop_n=0

    -- Signal.register('picked_up', function(e, c_pickable)
    --     self.picked_up=true
    -- end)
end

--===========================#
--

C_LifeUp = Class('C_LifeUp', Comp)


function C_LifeUp:__construct(e, size)
    Comp.__construct(self, e)
    --=
    self.timer = 0
    self.blink_at = 5
    self.erase_at = self.blink_at + 0.4
    self.timer2 = 0
    self.size = size
end

--===========================#
--

C_Pickable = Class('C_Pickable', Comp)

function C_Pickable:__construct(e, text)
    Comp.__construct(self, e)
    --=
    self.is_picked_up = false
    -- self.picked_by = nil
    -- self.timer = 0
    -- self.blink_at = 5
    -- self.erase_at = self.blink_at + 0.4

end

--===========================#
--

C_Debris = Class('C_Debris', Comp)

function C_Debris:__construct(e, text)
    Comp.__construct(self, e)
    --=
    self.timer = 0
    self.erase_at = love.math.random(0.2, 0.8)
end

--===========================#

C_Punch = Class('C_Punch', Comp)

function C_Punch:__construct(e, text)
    Comp.__construct(self, e)
    --=
    self.range = Tl.Dim * 0.6
    self.is_hero_in_range = false
end

--===========================#

C_Katana = Class('C_Katana', Comp)

function C_Katana:__construct(e, text)
    Comp.__construct(self, e)
    --=
    self.range = Tl.Dim * 1
    self.is_hero_in_range = false
end

--===========================#

C_Mine = Class('C_Mine', Comp)

function C_Mine:__construct(e, text)
    Comp.__construct(self, e)
    --=
    self.timer = 0
    self.remove_at = 20 --+ math.random(1, 6)
end
