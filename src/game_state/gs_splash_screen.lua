local GS_SplashScreen = Class('GS_SplashScreen', GameStateInterface)

function GS_SplashScreen:__construct()
    self.quotes =  {
        "Determination tempers the sword of your character.",
        "To be heard afar, bang your gong on a hilltop.",
        "Great doubts, deep wisdom. . . small doubts, little wisdom.",
        "Let not the sands of time get in your lunch.",
        "The camel can't see her own hump",
        "You're a Day Late and a Dollar Short",
        "You cannot catch tiger cubs without entering the tiger's lair",
    }

    return self
end

function GS_SplashScreen:load()
    self.timer = 0
    self.logo = love.graphics.newImage('asset/image/menu-logo.png')
    self.logo:setFilter('nearest', 'nearest')
    self.logo_w = self.logo:getWidth()
    self.logo_h = self.logo:getHeight()
    self.logo_y = love.graphics.getHeight() * 0.5 - self.logo_h
    self.logo_scale = love.graphics.getWidth() / self.logo_w * 0.75
    self.logo_x = love.graphics.getWidth() * 0.5 - self.logo_w * 0.5 * self.logo_scale

    local charset = {
        "中","国","野","外","天"," ","八","方","風",
        "語","茶","で","コ","ン","ピ","ュ","ー","タ",
        "の","界","が","広","が","り","ま",
    }

    local rand_i = love.math.random(#self.quotes)

    self.quote_en = self.quotes[rand_i]
    self.quote_jap = ""

    for i=1, #self.quote_en do
        local ascii_code = string.byte(self.quote_en, i)
        local c = string.char(ascii_code)

        if (c == " " or c == "!" or c == '.') and love.math.random(100) > 50 then
            self.quote_jap = self.quote_jap .. c
        else
            self.quote_jap = self.quote_jap .. charset[1 + (ascii_code % #charset)]
        end
    end

    self.quote_en = "* " .. self.quote_en .. " *"
    self.quote_jap = "#" .. rand_i .. ' ~ ' .. self.quote_jap
    return self
end

function GS_SplashScreen:update(dt)
    self.timer = self.timer + dt
    if self.timer > 4 then
        GAME_STATE_MACHINE:push(GS_MainMenu():load())
    end
end

function GS_SplashScreen:draw()
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.draw(self.logo, self.logo_x, self.logo_y, 0, self.logo_scale, self.logo_scale)    

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(FONT.JAP)
    love.graphics.printf(self.quote_jap, 0, love.graphics.getHeight() * 0.5, love.graphics.getWidth(), 'center')

    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.setFont(FONT.JAP)
    love.graphics.printf(self.quote_en, 0, love.graphics.getHeight() - 50, love.graphics.getWidth(), 'center')
end

function GS_SplashScreen:keypressed(k)
    if k == 'escape' then
        love.event.quit()
    end
end

return GS_SplashScreen