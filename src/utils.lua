Utils={}

Utils.round = function(n)
    local decimal = n - math.floor(n)
    return decimal < 0.5 and math.floor(n) or math.ceil(n)
end


-- Save copied tables in `copies`, indexed by original table.
table.deepcopy = function(orig)
    local orig_type = type(orig)
    local copy = {}
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
        end
        -- setmetatable(copy, table.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function table.clone(org)
    return {unpack(org)}
end

function table.slice(t, first, last, step)
    local sliced = {}

    for i = first or 1, last or #t, step or 1 do
      sliced[#sliced+1] = t[i]
    end

    return sliced
end

function table.remove_by_value(t, val)
    for i, v in ipairs(t) do
        if v == val then
            table.remove(t, i)
            return
        end
    end
end

function table.filter(t, f)
    local filtered = {}
    for i, v in ipairs(t) do
        if f(v, i) then
            filtered[#filtered+1] = v
        end
    end
    return filtered
end

function table.min(t, f)
    local min = nil
    for i, v in ipairs(t) do
        if min == nil or f(v) < f(min) then
            min = v
        end
    end
    return min
end

function table.random(t)
    if t and #t > 0 then
        return t[math.random(#t)]
    end
    return nil
end

function table.contains(t, val)
    for _, v in ipairs(t) do
        if v == val then
            return v
        end
    end
    return nil
end

function math.lerp(a, b, t)
    return a + (b - a) * t
end

function math.inverse_lerp(a, b, v)
    return (v - a) / (b - a)
end

function math.remap(i_min, i_max, o_min, o_max, value)
    local t = math.inverse_lerp(i_min, i_max, value)
    return math.lerp(o_min, o_max, t)
end

function math.clamp(x, min, max)
    return x < min and min or (x > max and max or x)
end

function math.sign(x)
    return x > 0 and 1 or (x < 0 and -1 or 0)
end

function math.round(x)
    return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

function math.distance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function math.angle(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

function math.angle_difference(a1, a2)
    local diff = (a2 - a1 + math.pi) % (math.pi * 2) - math.pi
    return diff < -math.pi and diff + math.pi * 2 or diff
end

function math.angle_lerp(a1, a2, t)
    return a1 + math.angle_difference(a1, a2) * t
end

function math.random_choice(t)
    return t[math.random(#t)]
end

function math.random_normal(mean, stddev)
    stddev = stddev or 1.0
    mean = mean or 0.0
    local x1, x2, w
    repeat
        x1 = 2.0 * math.random() - 1.0
        x2 = 2.0 * math.random() - 1.0
        w = x1 * x1 + x2 * x2
    until w < 1.0
    w = math.sqrt((-2.0 * math.log(w)) / w)
    return mean + x1 * w * stddev
end

-- = Kinematic Distance =--
-- = v = initial velocity
-- = a = acceleration
-- = t = time
-- = returns distance after time t
function math.kinematic_distance(v, a, t)
    return v * t + 0.5 * a * t * t
end

-- = Kinematic Velocity =--
-- = v = initial velocity
-- = a = acceleration
-- = t = time
-- = returns velocity after time t
function math.kinematic_velocity(v, a, t)
    return v + a * t
end

-- = Kinematic Initial Velocity =--
-- = vf = final velocity
-- = a = acceleration
-- = t = time
function math.kinematic_initial_velocity(vf, a, t)
    return vf - a * t
end

-- = Kinematic Time =--
-- = v = initial velocity
-- = a = acceleration
-- = d = initial distance
-- = returns time to reach distance d
function math.kinematic_time(v, a, d)
    if a == 0 then
        return d / v
    end
    return (math.sqrt(v * v + 2 * a * d) - v) / a
end

-- = Kinematic Acceleration =--
-- = v = initial velocity
-- = a = acceleration
-- = d = initial distance
-- = returns acceleration to reach distance d
function math.kinematic_acceleration(v, a, d) 
    return (math.sqrt(v * v + 2 * a * d) - v) / d
end

-- = returns acceleration to reach distance d in time t with gravity g
function math.kinematic_acceleration2(d, t, g)
    return (2 * d) / (t * t) - g
end

-- = Kinematic Distance =--
-- = v0 = initial velocity
-- = vf = final velocity
-- = a = acceleration
-- = returns distance to reach final velocity
function math.kinematic_distance2(v0, vf, a)
    return (vf * vf - v0 * v0) / (2 * a)
end

function math.vector_to_angle(x, y)
    return math.atan2(y, x)
end

function math.angle_to_vector(angle)
    return math.cos(angle), math.sin(angle)
end

function math.vector_length(x, y)
    return math.sqrt(x * x + y * y)
end

function math.vector_normalize(x, y)
    local length = math.vector_length(x, y)
    return x / length, y / length
end

function math.vector_rotate(x, y, angle)
    local c, s = math.cos(angle), math.sin(angle)
    return x * c - y * s, x * s + y * c
end

function math.vector_scale(x, y, scale)
    return x * scale, y * scale
end

function math.vector_lerp(x1, y1, x2, y2, t)
    return x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
end

function math.vector_dot(x1, y1, x2, y2)
    return x1 * x2 + y1 * y2
end

function math.noise1d(x)
    local ix = math.floor(x)
    local fx = x - ix
    local a = math.random()
    local b = math.random()
    return math.lerp(a, b, fx)
end

function math.noise2d(x, y)
    local ix = math.floor(x)
    local iy = math.floor(y)
    local fx = x - ix
    local fy = y - iy
    local a = math.noise1d(ix + iy * 57)
    local b = math.noise1d(ix + 1 + iy * 57)
    local c = math.noise1d(ix + (iy + 1) * 57)
    local d = math.noise1d(ix + 1 + (iy + 1) * 57)
    local x1 = math.lerp(a, b, fx)
    local x2 = math.lerp(c, d, fx)
    return math.lerp(x1, x2, fy)
end

function math.segToRect(x1, y1, x2, y2)
    local x, y, w, h
    if x1 < x2 then
        x = x1
        w = x2 - x1
    else
        x = x2
        w = x1 - x2
    end
    if y1 < y2 then
        y = y1
        h = y2 - y1
    else
        y = y2
        h = y1 - y2
    end
    return x, y, w, h
end


function rgb_to_factor(color)
    return {color[1] / 255, color[2] / 255, color[3] / 255}
end

function neatnumber(n)
    local s, i = string.format('%0.f', n)
    repeat
        s, i = s:gsub('^(%-?%d+)(%d%d%d)', '%1,%2')
    until i == 0
    return s
end

function string.split(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

love.graphics.newGradientMesh = function(dir, ...)
    local COLOR_MUL = love._version >= "11.0" and 1 or 255
    local ALPHA = 0.7
    -- Color multipler
    -- Check for direction
    local isHorizontal = true
    if dir == "vertical" then
        isHorizontal = false
    elseif dir ~= "horizontal" then
        error("bad argument #1 to 'gradient' (invalid value)", 2)
    end
    -- Check for colors
    local colorLen = select("#", ...)
    if colorLen < 2 then
        error("color list is less than two", 2)
    end
    -- Generate mesh
    local meshData = {}
    if isHorizontal then
        for i = 1, colorLen do
            local color = select(i, ...)
            local x = (i - 1) / (colorLen - 1)

            meshData[#meshData + 1] = {x, 1, x, 1, color[1], color[2], color[3], color[4] or (1 * COLOR_MUL * ALPHA)}
            meshData[#meshData + 1] = {x, 0, x, 0, color[1], color[2], color[3], color[4] or (1 * COLOR_MUL) * ALPHA}
        end
    else
        for i = 1, colorLen do
            local color = select(i, ...)
            local y = (i - 1) / (colorLen - 1)

            meshData[#meshData + 1] = {1, y, 1, y, color[1], color[2], color[3], color[4] or (1 * COLOR_MUL * ALPHA)}
            meshData[#meshData + 1] = {0, y, 0, y, color[1], color[2], color[3], color[4] or (1 * COLOR_MUL * ALPHA)}
        end
    end
    -- Resulting Mesh has 1x1 image size
    return love.graphics.newMesh(meshData, "strip", "static")
end