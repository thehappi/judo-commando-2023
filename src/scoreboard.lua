local GJ = GJ or require "gamejolt.init"
local Scoreboard = Class("Scoreboard")

function Scoreboard:__construct()
    self.personal = {}
    self.online = {}
end

function Scoreboard:connect()
    local res_init, res_auth = nil, nil

    if GJ.isLoggedIn then
        return true
    end
    res_init = GJ.init(813493, "bb334d57f416704edff84fcb8ed6a17c")
    res_auth = GJ.authUser("albiengauthier", "VbwXPz")

    return res_init and res_auth
end

function Scoreboard:saveOnline(new_score, username)
    username = username or "anonymous"

    self:connect()
    self:fetchOnline()
    if GJ.isLoggedIn then
        local nth = self:isNewBest(self.online, new_score)
        if nth then
            table.insert(self.online, nth, {score = new_score, name = username, is_new_best=true})
            table.remove(self.online)
            GJ.addScore(new_score, username)
            return nth
        end
    end
    return false
end

function Scoreboard:savePersonal(new_score, username)
    username = username or "anonymous"

    self:fetchLocal()
    local nth = self:isNewBest(self.personal, new_score)
    if nth then
        table.insert(self.personal, nth, {score = new_score, name = username, is_new_best=true})
        table.remove(self.personal)
        self:saveLocalData()
        return nth
    end
    return false
end

function Scoreboard:saveLocalData()
    local data = {}
    for _, entry in ipairs(self.personal) do
        table.insert(data, entry.name)
        table.insert(data, entry.score)
    end
    print(table.concat(data, "\n"))
    print(love.filesystem.write("scoreboard.dat", table.concat(data, "\n")))
end

function Scoreboard:loadLocalData()
    local data = love.filesystem.read("scoreboard.dat")
    if data then
        local entries = {}

        data = string.split(data, "\n")
        for i = 1, #data, 2 do
            print("i", i, data[i], data[i+1])
            table.insert(entries, {name=data[i], score=tonumber(data[i+1])})
        end
        return entries
    end
    return SCOREBOARD.DEFAULT_ENTRIES
end


function Scoreboard:fetchOnline(nth_first)
    nth_first = nth_first or 7

    if not GJ.isLoggedIn then
        self.online = {}
    else
        self.online = GJ.fetchScores(nth_first)
        self.online = self:unserializeOnline(self.online)
    end
    return self.online
end

function Scoreboard:unserializeOnline(online_entries)
    local unserialized = {}

    for _, entry in ipairs(online_entries) do
        local name = entry.score -- !? WTF - score is name, sort is score !?
        local score = tonumber(entry.sort)
        table.insert(unserialized, {name=name, score=score})
    end
    return unserialized
end

function Scoreboard:fetchLocal(nth_first)
    nth_first = nth_first or 7
    self.personal = table.slice(self:loadLocalData(), 1, nth_first)
end

function Scoreboard:isNewBest(scoreboard, new_score)
    for i, entry in ipairs(scoreboard) do
        if new_score > entry.score then
            return i
        end
    end
    return nil
end

return Scoreboard()