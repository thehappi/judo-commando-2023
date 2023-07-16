--============= DEBUG MENU STATE ==============#

GS_DebugMenu = Class('GS_DebugMenu')

function GS_DebugMenu:__construct()
    self.i = 1
    self.len = 0
    return self
end

function GS_DebugMenu:load()
    self.t_ordered, self.len = self:loadOrderedPairs(CONST)
    self.path = {}
    return self
end

function GS_DebugMenu:getValueTypeAt(i)
    local v = orderedGet(self.t_ordered, i)
    if type(v) == 'table' then
        if type(v[1]) == 'number' and type(v[2]) == 'number' then
            return 'number'
        else
            return 'table'
        end
    else
        error('GS_DebugMenu:getValueTypeAt() - value format : {default_value, threshold}')
    end
end

function GS_DebugMenu:setConstTableValue(i, value)
    local it = CONST
    for _, v in ipairs(self.path) do
      it = it[v]
    end
    it = it[self.t_ordered[self.i]]
    it[1] = value
end

function GS_DebugMenu:keypressed(k)
    -- = navigate up and down through the table
    if k == 'up' then
        self.i = self.i - 1
        if (self.i < 1) then self.i = self.len end
    elseif k == 'down' then
        self.i = self.i + 1
        if (self.i > self.len) then self.i = 1 end
    end
    -- = get the value at the current index
    local v = orderedGet(self.t_ordered, self.i)
    -- = if the value is a number, increment or decrement it with left and right
    if self:getValueTypeAt(self.i) == 'number' then
        local value = nil
        local threshold = nil
        value = v[1]
        threshold = v[2]
        if k == 'left' then
            -- orderedSet(self.t_ordered, self.i, value - threshold)
            self:setConstTableValue(self.i, value - threshold)
        elseif k == 'right' then
            -- orderedSet(self.t_ordered, self.i, value + threshold)
            self:setConstTableValue(self.i, value + threshold)
        end
    -- = if the value is a table, go into it with return or right
    elseif self:getValueTypeAt(self.i) == 'table' and (k == 'right' or k == 'return') then  
      self.path[#self.path+1] = self.t_ordered[self.i]
      self.i = 1
      self.t_ordered, self.len = self:loadOrderedPairs(v)
    end
    -- = go back to the previous table with backspace    
    if k == 'backspace' and #self.path > 0 then
        if #self.path == 0 then 
            return
        elseif #self.path == 1 then -- = if we are at the root, load the const table
            self.t_ordered, self.len = self:loadOrderedPairs(CONST)
        else -- = otherwise load the previous table
            self.t_ordered, self.len = self:loadOrderedPairs(self.path[#self.path])
        end

        self.i = 1
        self.path[#self.path] = nil
    end

    if k == 'escape' then
      GAME_STATE_MACHINE:pop()
    end
end

function GS_DebugMenu:update()
end


function GS_DebugMenu:draw()
    local path_x = 10
    local path_y = 10
    local sx = path_x
    local sy = path_y + 50
    local mb = 20 -- = margin bottom between items

    -- = print complete path
    local path_str = "path:   ROOT - "
    for _, v in ipairs(self.path) do
        path_str = path_str .. v .. " - "
    end
    love.graphics.setColor(255,255,255)
    love.graphics.print(path_str, path_x + 100, path_y)

    -- = print items
    for i, k, v in orderedPairs(self.t_ordered) do
        local x = sx
        local y = sy + (i-1) * 10 + mb * (i-1)
        -- = highlight hovered item
        if self.i == i then
            love.graphics.setColor(255,0,0)
        else
            love.graphics.setColor(255,255,255)
        end
        -- = print item key
        love.graphics.print(k, x, y)
        -- = print item value
        if self:getValueTypeAt(self.i) == "table" then -- = table <=> directory
            love.graphics.print("dir.", x + 300, y)
        else -- = number
            v = type(v) == 'table' and v[1] or v
            love.graphics.print(v, x + 300, y)
        end
    end
end

function GS_DebugMenu:loadOrderedPairs(t)
  local ordered = table.ordered()
  local len = 0
  for k,v in pairs(t) do
      -- = ordered[k] = (self:getValueTypeAt(self.i) == "table") and self:loadOrderedPairs(v) or v
      ordered[k] = v
      len = len + 1
  end
  return ordered, len
end