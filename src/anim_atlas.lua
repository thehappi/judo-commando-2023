local AnimProp = AnimProp or require 'anim.anim_prop'

Spritesheet={
    Hero=
        love.graphics.newImage('asset/hero.png'),
    Enemy=
        love.graphics.newImage('asset/military_base.png'),
    Enemy_Gun=
        love.graphics.newImage('asset/military_pistol.png'),
    Enemy_Rocket=
        love.graphics.newImage('asset/military_rocket.png'),
    Enemy_Mine=
        love.graphics.newImage('asset/military_mine.png'),
    Enemy_Ninja=
        love.graphics.newImage('asset/ninja.png'),
    Enemy_Monkey=
        love.graphics.newImage('asset/monkey.png'),
    Item_And_Fx=
        love.graphics.newImage('asset/items.png'),
}

Atlas={
    Hero={},
    Enemy = {
        Base={},
        Gun={},
        Rocket={},
        Bomb={},
        Ninja={},
        Monkey={}
    },
    Item={},
    Fx={},
    Particle={},
    Jewel={}
}

local A = Atlas

--===========================#
--          HERO

A.Hero['idle'] = AnimProp(Spritesheet.Hero)
    :contiguous(V2(0,0), V2(32,38),  9, 450)
    -- :dup(1, 1)
    :dup(7, 2)
    :loop()

A.Hero['run'] = AnimProp(Spritesheet.Hero)
    :contiguous(V2(0,38), V2(32,32), 12, 800)
    -- :dupAll(1)
    :dup(3, 1)
    :dup(4, 1)
    :dup(9, 1)
    :dup(10, 1)
    :loop()

A.Hero['jump'] = AnimProp(Spritesheet.Hero)
    :contiguous(V2(0,262), V2(32,34), 8, 100)

A.Hero['duck'] = AnimProp(Spritesheet.Hero)
    :contiguous(V2(224,70), V2(32,32), 2, 80)

A.Hero['ladder'] = AnimProp(Spritesheet.Hero)
    :contiguous(V2(416,38), V2(32,32), 2, 200)
    :loop()

A.Hero['corner_climb'] = AnimProp(Spritesheet.Hero)
    :contiguous(V2(0,451), V2(34,61), 9, 500 )
    :dup(2,4)
    :dup(8)

A.Hero['platf_move'] = AnimProp(Spritesheet.Hero)
    :contiguous(V2(0,70), V2(32,32), 6, 1200)
    :loop()

A.Hero['platf_climb'] = AnimProp(Spritesheet.Hero)
    :contiguous(V2(331,451), V2(32,50), 5, 400)

A.Hero['get_hit']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(288, 262), V2(32, 34), 1, 500 )

A.Hero['hit_ground']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(390,360), V2(34,32), 3, 600)
    :dup(3, 8)

A.Hero['stand_up']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(320,134), V2(32, 32), 2, 500 )

A.Hero['getup']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(320,134), V2(32, 32), 2, 100 )

A.Hero['combo1_idle']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(0,134), V2(32, 32), 1, 500 )
    
A.Hero['combo1_u']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(224,134), V2(32, 32), 2, 100 )

A.Hero['combo1_back']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(416,134), V2(32, 32), 3, 250 )
    :dup(1) -- = mucho importante

A.Hero['combo1_forward']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(64,134), V2(32, 32), 4, 250 )

A.Hero['combo2_enter']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(0,166), V2(32, 32), 4, 250 )
    :dup(2)

A.Hero['combo2_idle']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(96,166), V2(32, 32), 1, 400 )

A.Hero['combo2_walk']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(224,166), V2(32, 32), 8, 1000 )
    :loop()

A.Hero['combo2_throw_forward']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(128,166), V2(32, 32), 2, 275 )
    :dup(1)
    :dup(2,2)

A.Hero['combo3_enter']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(384,262), V2(32, 38), 4, (350) )
    :dup(4, 2)

A.Hero['combo3_idle']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(480,262), V2(32, 38), 1, 300 )

A.Hero['combo3_walk']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(96,198), V2(32, 32), 8, 1000 )
    :loop()

A.Hero['combo3_kick']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(386,304), V2(42, 42), 3, 200 )
    :dup(1, 2)

A.Hero['combo3_d']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(448,198), V2(32, 32), 2, 200 )
    :dup(2, 5)

A.Hero['combo3_u']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(0,230), V2(32, 32), 4, 300 )
    :dup(2)

A.Hero['combo_armlock']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(160,230), V2(32, 32), 7, 600 )
    :dup(1, 3)

A.Hero['combo_meteor']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(384,102), V2(32, 32), 4, 200 )

A.Hero['onen_enter']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(0,328), V2(32, 32), 5, 350 )

A.Hero['onen_idle']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(128, 102), V2(32, 32), 1, 1000 )

A.Hero['onen_punch']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(192,102), V2(32, 32), 2, 200 )
    :dup(1, 2)

A.Hero['onen_d']=AnimProp(Spritesheet.Hero)
    :contiguous(V2(2,410), V2(42, 38), 10, 750 )
    -- :dup(3)
    :dup(7)




--===========================#
--          ENEMY

A.Enemy.Base['walk']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(142,0), V2(32,34),  7, 700)
    :loop()

A.Enemy.Base['idle']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(142,0), V2(32,34),  1, 700)
    :loop()

A.Enemy.Base['gethit']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(2,258), V2(38,36), 2, 200 )

A.Enemy.Base['hit_ground']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(132,76), V2(34,32), 3, 600)
    :dup(3, 8)

A.Enemy.Base['hit_ceil']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(36,224), V2(34,32), 3, 150)

A.Enemy.Base['hit_wall']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(140,224), V2(32,34), 1, 40)

A.Enemy.Base['getup']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(68,112), V2(32,32), 2, 200 )
    :dup(1)

A.Enemy.Base['duck']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(344,76), V2(32,32), 3, 80)

A.Enemy.Base['ladder']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(0,38), V2(32,34), 2, 200)
    :loop()

A.Enemy.Base['jump']=AnimProp(Spritesheet.Enemy)
    -- :contiguous(V2(0,188), V2(32,34), 8, 100) OLD ANIM
    :contiguous(V2(2, 296), V2(34,34), 7, 100)

A.Enemy.Base['combo1_idle']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(0,0), V2(32, 34), 1, 500 )

A.Enemy.Base['onguard2']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(32,112), V2(32, 32), 1, 500 )

A.Enemy.Base['combo3_enter']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(224,112), V2(32, 34), 3, 500 )

A.Enemy.Base['combo3_idle']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(320,112), V2(32, 38), 1, 500 )

A.Enemy.Base['combo3_kicked']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(224,112), V2(32, 34), 3, 400 )

A.Enemy.Base['combo3_ued']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(144, 148), V2(36, 36), 2, 200 )

A.Enemy.Base['hero_landing_over']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(344, 76), V2(32, 32), 5, 350 )

A.Enemy.Base['on_hero_over_throw']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(344, 76), V2(32, 32), 1, 250 )

A.Enemy.Base['on_hero_over_punch']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(256, 147), V2(32, 34), 1, 80 )--:dup(2, 1)

A.Enemy.Base['punch']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(36, 0), V2(34,34), 3, 350)
    :dup(2)

A.Enemy.Base['gun']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(200,38), V2(32,34), 1, 600)

A.Enemy.Base['gun_duck']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(237,38), V2(32,34), 1, 600)

A.Enemy.Base['rocket']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(272,38), V2(32,34), 2, 200)

A.Enemy.Base['mine']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(344,76), V2(32,32), 3, 200)

A.Enemy.Base['combo_meteor']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(0,76), V2(32,32), 4, 200)

A.Enemy.Base['armlock']=AnimProp(Spritesheet.Enemy)
    :contiguous(V2(208, 224), V2(34,32), 1, 100)
    -- :dup(3, 8)

--===========================#
--          GUNNER
A.Enemy.Gun = table.deepcopy(A.Enemy.Base)
for k, anim_prop in pairs(A.Enemy.Gun) do
    if anim_prop.spritesheet == Spritesheet.Enemy then
        anim_prop.spritesheet = Spritesheet.Enemy_Gun
    end
end

--===========================#
--          ROCKETTER
A.Enemy.Rocket = table.deepcopy(A.Enemy.Base)
for k, anim_prop in pairs(A.Enemy.Rocket) do
    if anim_prop.spritesheet == Spritesheet.Enemy then
        anim_prop.spritesheet = Spritesheet.Enemy_Rocket
    end
end

--===========================#
--          BOMBER
A.Enemy.Bomb = table.deepcopy(A.Enemy.Base)
for k, anim_prop in pairs(A.Enemy.Bomb) do
    if anim_prop.spritesheet == Spritesheet.Enemy then
        anim_prop.spritesheet = Spritesheet.Enemy_Mine
    end
end

--===========================#
--          NINJA
A.Enemy.Ninja = table.deepcopy(A.Enemy.Base)
for k, anim_prop in pairs(A.Enemy.Ninja) do
    if anim_prop.spritesheet == Spritesheet.Enemy then
        anim_prop.spritesheet = Spritesheet.Enemy_Ninja
    end
end

A.Enemy.Ninja['katana']=AnimProp(Spritesheet.Enemy_Ninja)
    :contiguous(V2(82,262), V2(32,32), 7, 300)
A.Enemy.Ninja['shuriken']=AnimProp(Spritesheet.Enemy_Ninja)
    :contiguous(V2(328,38), V2(32,32), 1, 120)
A.Enemy.Ninja['on_hero_over_punch']=AnimProp(Spritesheet.Enemy_Ninja)
    :contiguous(V2(355, 112), V2(32, 34), 2, 80 ):dup(2, 1)
A.Enemy.Ninja['ninja_dash']=AnimProp(Spritesheet.Enemy_Ninja)
    :contiguous(V2(2, 296), V2(32, 38), 10, 600 ):dup(3, 1):dup(8, 1):loop()
A.Enemy.Ninja['ninja_jump']=AnimProp(Spritesheet.Enemy_Ninja)
    :contiguous(V2(260, 188), V2(32, 32), 4, 280 ):loop()
A.Enemy.Ninja['ninja_fall']=AnimProp(Spritesheet.Enemy_Ninja)
    :contiguous(V2(434, 38), V2(32, 36), 1, 1000 )
A.Enemy.Ninja['jump_kick']=AnimProp(Spritesheet.Enemy_Ninja)
    :contiguous(V2(260, 154), V2(32, 32), 2, 200 )

--===========================#
--          MONKEY

-- A.Enemy.Monkey = A.Enemy.Base
A.Enemy.Monkey['walk']=AnimProp(Spritesheet.Enemy_Monkey)
    :contiguous(V2(0,0), V2(42, 32), 12, 800)
    :loop()

A.Enemy.Monkey['monkey_jump']=AnimProp(Spritesheet.Enemy_Monkey)
    :contiguous(V2(68,38), V2(42, 32), 1, 100)

A.Enemy.Monkey['duck']=AnimProp(Spritesheet.Enemy_Monkey)
    :contiguous(V2(168,0), V2(42, 32), 3, 200)

A.Enemy.Monkey['claw']=AnimProp(Spritesheet.Enemy_Monkey)
    :contiguous(V2(118,38), V2(42, 32), 3, 200)

A.Enemy.Monkey['grab_hero_air']=AnimProp(Spritesheet.Enemy_Monkey)
    :contiguous(V2(0,76), V2(42, 32), 4, 500)
    -- :loop()

A.Enemy.Monkey['idle']=AnimProp(Spritesheet.Enemy_Monkey)
    :contiguous(V2(0,112), V2(42, 32), 10, 1000)
    -- :dup(5,2)
    -- :dup(9,2)
    :loop()

A.Enemy.Monkey['menu-idle']=AnimProp(Spritesheet.Enemy_Monkey)
    :contiguous(V2(0,242), V2(42, 32), 10, 2000)
    :loop()

    
A.Enemy.Monkey['grab_hero_ground1']=AnimProp(Spritesheet.Enemy_Monkey)
    :contiguous(V2(168,76), V2(42, 32), 3, 500)


A.Enemy.Monkey['grab_hero_ground2']=AnimProp(Spritesheet.Enemy_Monkey)
    :contiguous(V2(0,148), V2(42, 44), 9, 1000)
    -- :dup(5,2)
    -- :dup(9,2)
    -- :loop()

A.Enemy.Monkey['grab_hero_ground3']=AnimProp(Spritesheet.Enemy_Monkey)
    :contiguous(V2(0,196), V2(42, 44), 8, 800)


--===========================#
--          ITEMS

A.Item['bullet'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(40,0), V2(8,2), 2, 250):loop()
A.Item['rocket'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(40,4), V2(8,4), 2, 300):loop()
A.Item['mine'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(40,10), V2(8,4), 1, 200)
A.Item['shuriken'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(49,20), V2(8,8), 4, 200):loop()
A.Item['life_up_sm'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,0), V2(20,20), 1, 350)
A.Item['life_up_md'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(20,0), V2(20,20), 1, 350)

--===========================#
--          FX
-- A.Fx['on_bullet_hit'] = AnimProp(Spritesheet.Item_And_Fx)
--     :contiguous(V2(56,0), V2(18,18), 3, 200)
A.Fx['on_bullet_hit'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(124,80), V2(20,20), 4, 300)
    :dup(1, 1)
A.Fx['rocket_smoke'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,199), V2(28,26), 4, 400)--:dup(4, )
A.Fx['rocket_aiming'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(91,21), V2(33,32), 5, ROCKET_AIMING_ANIM_TIME * 1000)
    -- :dup(4)
    :dup(1)
A.Fx['flare'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,146), V2(32,32), 6, 200)
A.Fx['katana_trail'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(106,108), V2(36, 28), 2, 125)
    :dup(1)
    :dup(2,2)
A.Fx['item_picked_up'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,226), V2(32, 30), 9, 800)
A.Fx['flare'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,146), V2(32,32), 6, 200)
A.Fx['enemy_chase_mark'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,180), V2(10,10), 3, 500)
    :loop()

--===========================#
--          JEWELS
A.Jewel['nil'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,20), V2(18,14), 1, 300)
A.Jewel['red'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,34), V2(18,14), 5, 425):dup(3):dup(5)
A.Jewel['orange'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,48), V2(18,14), 5, 425):dup(3):dup(5)
A.Jewel['yellow'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,62), V2(18,14), 5, 425):dup(3):dup(5)
A.Jewel['green'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,76), V2(18,14), 5, 425):dup(3):dup(5)
A.Jewel['cyan'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,90), V2(18,14), 5, 425):dup(3):dup(5)
A.Jewel['blue'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,104), V2(18,14), 5, 425):dup(3):dup(5)
A.Jewel['purple'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,118), V2(18,14), 5, 425):dup(3):dup(5)
A.Jewel['pink'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(0,132), V2(18,14), 5, 425):dup(3):dup(5)

--===========================#
--          PARTICLES

A.Particle['level_clear'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(124,61), V2(18,18), 7, 350)
A.Particle['blood'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(21,20), V2(2,2), 1, 350)
A.Particle['spark'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(242,15), V2(2,2), 1, 350)
A.Particle['item_picked_up'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(184,0), V2(10,10), 3, 100) 
A.Particle['spark_md'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(240,7), V2(6,6), 1, 0) 
A.Particle['spark_md_white'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(196,2), V2(6,6), 1, 0) 

A.Particle.Debris = {} 
A.Particle.Debris['sm'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(21,20), V2(2,2), 1, 0)
A.Particle.Debris['md'] = AnimProp(Spritesheet.Item_And_Fx)
    :contiguous(V2(25,20), V2(4,4), 1, 0)
