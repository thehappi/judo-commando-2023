--===========================#
-- = Singleton

local GameSignal = {}

GameSignal.new = function()
    local o = {}
    return setmetatable(o, {__index = GameSignal})
end

function GameSignal:clear()
    Signal.clear('level-clear')
    Signal.clear('jewel-set-complete')
    Signal.clear('jewel-collected')
    Signal.clear('enemy-killed')
    Signal.clear('land-new-level')
end

function GameSignal:landNewLevel()
    Signal.emit('land-new-level')
end

function GameSignal:levelClear()
    Signal.emit('level-clear')
end

function GameSignal:jewelSetComplete()
    Signal.emit('jewel-set-complete')
end

function GameSignal:jewelCollected()
    Signal.emit('jewel-collected')
end

function GameSignal:enemyKilled(enemy)
    Signal.emit('enemy-killed', enemy)
end

return GameSignal