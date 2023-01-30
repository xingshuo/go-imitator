local Infra = require 'src.infra'
local Goroutine = require 'src.goroutine'

local Scheduler = Infra.NewStruct('Scheduler')

function Scheduler:init()
    self.m_mGoroutines = {} -- goroutine : true
    self.m_mTimers = {} -- timer : when
    self.m_gMain = nil -- main goroutine
end

function Scheduler:addTimer(timer, when)
    self.m_mTimers[timer] = when
end

function Scheduler:delTimer(timer)
    if self.m_mTimers[timer] then
        self.m_mTimers[timer] = nil
        return true
    end
    return false
end

function Scheduler:_checkTimeout()
    local nearest = -1
    local timeoutNum = 0
    local now = os.time()

    for timer, when in pairs(self.m_mTimers) do
        local dt = when - now
        if dt <= 0 then
            self.m_mTimers[timer] = nil
            timer:run()
            timeoutNum = timeoutNum + 1
        else
            if nearest == -1 or dt < nearest then
                nearest = dt
            end
        end
    end

    return timeoutNum, nearest
end

function Scheduler:newG(f, ...)
    local g = Goroutine.New(f, ...)
    self.m_mGoroutines[g] = true
    return g
end

function Scheduler:newMainG(f, ...)
    assert(self.m_gMain == nil, 're-create main goroutine')
    local g = self:newG(f, ...)
    g:setMain()
    self.m_gMain = g
    return g
end

function Scheduler:run()
    while true do
        local runQ
        repeat
            runQ = {} -- to be optimized
            for g in pairs(self.m_mGoroutines) do
                if g:isRunable() then
                    runQ[#runQ + 1] = g
                end
            end

            for _, g in pairs(runQ) do
                g:run()
                if g:isDead() then
                    self.m_mGoroutines[g] = nil
                    if g:isMain() then
                        self.m_gMain = nil
                        print('main goroutine process done')
                        return
                    end
                end
            end
        until #runQ == 0

        local timeoutNum, nearest = self:_checkTimeout()
        if nearest > 0 then
            os.sleep(nearest)
            self:_checkTimeout()
        else
            if timeoutNum == 0 then
                error('maybe all goroutines dead lock!')
            end
        end
    end

end

local M = {}

function M.New()
    local s = Scheduler:New()
    return s
end

return M