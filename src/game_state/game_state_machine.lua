local GameStateMachine = Class('GameStateMachine')

function GameStateMachine:__construct()
    self._stack = {}
end

function GameStateMachine:push(gamestate)
    local top = self:first()

    if top and top.backgrounded then
        top:backgrounded()
    end
    if gamestate.enter then
        gamestate:enter()
    end

    table.insert(self._stack, gamestate)
    return gamestate
end

function GameStateMachine:below()
    if #self._stack == 1 then
        return nil
    else
        return self._stack[#self._stack - 1]
    end
end

function GameStateMachine:pop()
    local removed = self._stack[#self._stack]
    if removed and removed.exit then
        removed:exit()
    end

    table.remove(self._stack)
    local gamestate = self:first()

    if gamestate and gamestate.foreground then
        gamestate:foreground()
    end
    collectgarbage("collect")
    -- print('pop', removed, #self._stack)
end

function GameStateMachine:first()
    return self._stack[#self._stack]
end

function GameStateMachine:set(gamestate)
    self:pop()
    self:push(gamestate)
end

function GameStateMachine:stack()
    return self._stack[#self._stack]
end

function GameStateMachine:empty()
    repeat
        self:pop()
    until #self._stack == 0
end

return GameStateMachine
