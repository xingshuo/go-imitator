local Infra = require 'src.infra'

local g_States = {
    Ready = 0,
    Running = 1,
    Suspend = 2,
    Dead = 3,
    Error = 4,

    [0] = 'Ready',
    [1] = 'Running',
    [2] = 'Suspend',
    [3] = 'Dead',
    [4] = 'Error',
}

local running_go = nil
local go_id = 1

local Goroutine = Infra.NewStruct('Goroutine')

function Goroutine:init(f, ...)
    self.m_ID = go_id
    go_id = go_id + 1
    self.m_IsMain = false
    self.m_State = g_States.Ready

    local n = select('#', ...)
    if n == 0 then
        self.m_Processor = coroutine.wrap(function ()
            f()
        end)
    else
        local args = {...}
        self.m_Processor = coroutine.wrap(function ()
            f(table.unpack(args, 1, n))
        end)
    end
end

function Goroutine:__tostring()
    return string.format("Goroutine-%s", self.m_ID)
end

function Goroutine:run(...)
    assert(self:isRunable(), 'run error Goroutine state:' .. g_States[self.m_State])
    running_go = self
    self.m_State = g_States.Running
    local ok, command = xpcall(self.m_Processor, debug.traceback, ...)
    if not ok then
        self.m_State = g_States.Error
        error(command)
    end
    if command == 'SUSPEND' then
        self.m_State = g_States.Suspend
    elseif command == nil then
        self.m_State = g_States.Dead
    else
        self.m_State = g_States.Error
        error('unknown Goroutine yield command: ' .. command)
    end
end

function Goroutine:setReady()
    self.m_State = g_States.Ready
end

function Goroutine:isRunable()
    return self.m_State == g_States.Ready
end

function Goroutine:isDead()
    return self.m_State == g_States.Dead
end

function Goroutine:setMain()
    self.m_IsMain = true
end

function Goroutine:isMain()
    return self.m_IsMain
end

local M = {}

function M.New(f, ...)
    local g = Goroutine:New(f, ...)
    return g
end

function M.Running()
    return running_go
end

return M