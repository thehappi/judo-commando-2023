AssetManager = Class("AssetManager")

function AssetManager:__construct()
    self._images = {}
end

function AssetManager:loadImage(name)
    if not self._images[name] then
        self._images[name] = love.graphics.newImage("assets/images/" .. name .. ".png")
    end
    return self._images[name]
end
