local Infra = require 'src.infra'
local Goroutine = require 'src.goroutine'

WaitGroup = Infra.NewStruct('WaitGroup')

function WaitGroup:init()
    self.m_iRef = 0
    self.m_gWait = nil
end

function WaitGroup:Add(delta)
    assert(delta > 0)
    self.m_iRef = self.m_iRef + delta
end

function WaitGroup:Done()
    self.m_iRef = self.m_iRef - 1
    if self.m_iRef <= 0 then
        if self.m_gWait then
            goready(self.m_gWait)
        end
        return true
    end
end

function WaitGroup:Wait()
    if self.m_iRef > 0 then
        assert(self.m_gWait == nil)
        self.m_gWait = Goroutine.Running()
        gopark()
        self.m_gWait = nil
    end
end

local M = {}

function M.NewWaitGroup()
    return WaitGroup:New()
end

return M