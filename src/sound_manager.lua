local SoundManager = Class("SoundManager")

function SoundManager:__construct()
    self.sound = {
        blip = love.audio.newSource("asset/sound/blip.wav", "static"),
    }
    self.music = {
        menu = love.audio.newSource("asset/music/They Live - Transient Hotel.mp3", "stream"),
    }
    self.music.menu:setLooping(true)
    self.music.menu:setVolume(0.5)

    self.loop_start = 27.325
    self.loop_end = 60 + 21

    self.music.menu:setPitch(0.75)
    self.music.menu:seek(self.loop_start)
    -- self.music.menu:play()
end

function SoundManager:update()
    local pos = self.music.menu:tell()
    if self.loop_start < self.loop_end then -- usual case
        if pos < self.loop_start or pos > self.loop_end then
            self.music.menu:seek(self.loop_start) -- needs a modulo iirc.
        end
    end
end

return SoundManager()
