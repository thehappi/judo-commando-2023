local UI_Scoreboard = Class("UI_Scoreboard")

function UI_Scoreboard:__construct(title, x, y)
    self.x = x or 0
    self.y = y or 0
    self.w = 200

    -- self.h = 30

    self.title = {
        text = title or "Scoreboard",
        font = FONT.MAIN_MENU,
        color = {1, 0.8, 0, 1},
        x = self.x,
        y = self.y,
        margin_bot = 50,
    }
    self.scores = {
        entries = {},
        font = FONT.SCORE,
        margin_bot = 30,
    }
    self.new_best = {
        blink_t = 0,
        blink_interval = 0.25,
        is_visible = true,
    }
end

local __getRankColor = function(self, rank_i)
    local color = {0.9, 0.9, 0.9, 1} -- default color
    if rank_i == 1 then
        color = {1, 0, 0, 1}
    elseif rank_i == 2 then
        color = {0, 0.5, 0.5, 1}
    elseif rank_i == 3 then
        color = {1, 0.5, 0, 1}
    end
    return color
end

local __rankToString = function(rank_i)
    return rank_i .. '.'
    -- local rank = rank_i
    -- if rank_i == 1 then
    --     rank = '1st'
    -- elseif rank_i == 2 then
    --     rank = '2nd'
    -- elseif rank_i == 3 then
    --     rank = '3rd'
    -- else
    --     rank = rank_i..'th'
    -- end
    -- return rank
end

local __drawEntry = function(self, rank_i, name, score, is_new_best)
    local rank = __rankToString(rank_i)
    local name = string.sub(name, 1, 6)

    local x = self.x
    local y = self.y + self.title.margin_bot + (rank_i-1) * self.scores.margin_bot

    --= new best score - blink update
    if is_new_best then
        self.new_best.blink_t = self.new_best.blink_t + love.timer.getDelta()
        if self.new_best.blink_t > self.new_best.blink_interval then
            self.new_best.blink_t = 0
            self.new_best.is_visible = not self.new_best.is_visible
        end
    end

    if is_new_best and not self.new_best.is_visible then
        return
    end
    love.graphics.printf(
        rank, (x-36), y, self.w, 'left'
    )
    love.graphics.printf(
        name, x, y, (self.w*.5), 'right'
    )
    love.graphics.printf(
        neatnumber(score), (x+160), y, (self.w*.5), 'left'
    )
end

local __drawScoreEntries = function(self)
    for rank_i, entry in ipairs(self.scores.entries) do
        local color = __getRankColor(self, rank_i)
        local is_new_best = entry.is_new_best
        
        love.graphics.setColor(color)
        if entry.score and entry.name then
            __drawEntry(self, rank_i, entry.name, entry.score, is_new_best)
        end
    end
end


function UI_Scoreboard:add(name, score, is_new_best)
    table.insert(self.scores.entries, {name=name, score=score, is_new_best=is_new_best})
end


function UI_Scoreboard:draw()
    -- = draw title
    love.graphics.setFont(self.title.font)
    love.graphics.setColor(self.title.color)
    love.graphics.printf(self.title.text, self.title.x, self.title.y, self.w, 'center')
    -- = draw score entries
    love.graphics.setFont(self.scores.font)
    __drawScoreEntries(self)
end

function UI_Scoreboard:setEntries(entries)
    self.scores.entries = entries
end

function UI_Scoreboard:setTitle(title)
    self.title.text = title
end

return UI_Scoreboard








