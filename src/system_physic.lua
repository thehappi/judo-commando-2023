local Tiny = Tiny or require 'lib.tiny'

S_Physic=Tiny.processingSystem()
S_Physic.active=false

function S_Physic:filter(e)
    return e:has_active('c_b') and not Xtype.is(e, E_Tile) and not e.c_b.is_static
end

function S_Physic:process(e, dt)
    local c_b=e.c_b
    local c_pad=e.c_pad
    local FALL_ACC= c_b.fall_acc or Tl.Dim*36
    FALL_ACC=FALL_ACC*dt
    local FALL_MAX=c_b.fall_max or Tl.Dim*20
    local pad_r = c_pad and c_pad:is_pressed('right')
    local pad_l = c_pad and c_pad:is_pressed('left')

    local vx=c_b.vx
    local vy=c_b.vy

    -- = move horizontaly
    if e:has_active('c_move_hrz') then
        local c_move=e.c_move_hrz
        -- = acceleration
        if pad_r then
            vx=vx+c_move.acc*dt
            if vx > c_move.max then vx=c_move.max end
        elseif pad_l then
            vx=vx-c_move.acc*dt
            if vx < -c_move.max then vx=-c_move.max end
        end
         -- = deceleration
         if vx > 0 then
            if pad_l then
                vx=0
            elseif not pad_r then
                vx=vx-c_move.dec*dt
                if vx<c_move.min then vx=0 end
            end
        elseif vx < 0 then
            if pad_r then
                vx=0
            elseif not pad_l then
                vx=vx+c_move.dec*dt
                if vx>-c_move.min then vx=0 end
            end
        end    
    end

    if c_b.dec_x then
        if vx > 0 then
            vx=vx-c_b.dec_x*dt
            if vx<0 then 
                vx=0
                c_b.dec_x=nil 
            end
        elseif vx < 0 then
            vx=vx+c_b.dec_x*dt
            if vx>0 then
                vx=0
                c_b.dec_x=nil 
            end
        end
    end


    
    -- if e:has('c_move_hrz') then
    --     local c_move=e.c_move_hrz
    --     -- = deceleration
    --     if vx > 0 then
    --         if pad_l then
    --             vx=0
    --         elseif not pad_r then
    --             vx=vx-c_move.dec*dt
    --             if vx<c_move.min then vx=0 end
    --         end
    --     elseif vx < 0 then
    --         if pad_r then
    --             vx=0
    --         elseif not pad_l then
    --             vx=vx+c_move.dec*dt
    --             if vx>-c_move.min then vx=0 end
    --         end
    --     end        
    -- end

    -- = jump
    -- if c_b.is_on_ground then

        -- if (e:has_active('c_jump_act')) then
        --     local c_jmp = e.c_jump_act
        --     if pad_a then
        --         vy=c_jmp.impulse_y
        --     else
        --         vy=0
        --     end
        -- end
    if c_b.has_hit_ceil then
        vy=0
    elseif e:has_active('c_gravity') then -- = fall/gravity
        vy=vy+FALL_ACC
        -- if vy > FALL_MAX then vy=FALL_MAX end
    elseif not e:has_active('c_gravity') then
        -- vy=0
    end
    --=
    c_b.vx=vx
    c_b.vy=vy
end