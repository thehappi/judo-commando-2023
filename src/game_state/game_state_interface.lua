local GameStateInterface = Class('GameStateInterface')

function GameStateInterface:__construct()
    self.load =
        function (self) end
    self.update =
        function (self, dt) end
    self.draw =
        function (self) end
    self.keypressed =
        function (self,k) end
end

return GameStateInterface