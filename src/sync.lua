local Infra = require 'src.infra'
local Goroutine = require 'src.goroutine'

local WaitGroup = Infra.NewStruct('WaitGroup')

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


local Mutex = Infra.NewStruct('Mutex')

function Mutex:init()
    self.m_lWaiters = {} -- wait lock goroutine list
    self.m_gHolder = nil -- cur lock holder goroutine
end

function Mutex:Lock()
    local g = Goroutine.Running()
    repeat
        if self.m_gHolder == nil then
            self.m_gHolder = g
            break
        end
        self.m_lWaiters[#self.m_lWaiters + 1] = g
        gopark()
    until false
end

function Mutex:Unlock()
    if self.m_gHolder == nil then
        panic("unlock of unlocked mutex")
    end
    self.m_gHolder = nil
    if #self.m_lWaiters > 0 then
        local gnxt = table.remove(self.m_lWaiters, 1)
        goready(gnxt)
    end
end


local RWMutex = Infra.NewStruct('RWMutex')

function RWMutex:init()
    self.m_nReadCount = 0
    self.m_gWriter = nil
    self.m_lWWaiters = {} -- write waiters
    self.m_lRWaiters = {} -- read waiters
end

function RWMutex:RLock()
    local g = Goroutine.Running()
    repeat
        if self.m_gWriter == nil then
            self.m_nReadCount = self.m_nReadCount + 1
            break
        end
        self.m_lRWaiters[#self.m_lRWaiters + 1] = g
        gopark()
    until false
end

function RWMutex:RUnlock()
    assert(self.m_nReadCount > 0, "sync: RUnlock of unlocked RWMutex")
    self.m_nReadCount = self.m_nReadCount - 1
    if self.m_nReadCount == 0 then
        if #self.m_lWWaiters > 0 then
            local g = table.remove(self.m_lWWaiters, 1)
            goready(g)
        end
    end
end

function RWMutex:Lock()
    local g = Goroutine.Running()
    repeat
        if self.m_nReadCount == 0 and self.m_gWriter == nil then
            self.m_gWriter = g
            break
        end
        self.m_lWWaiters[#self.m_lWWaiters + 1] = g
        gopark()
    until false
end

function RWMutex:Unlock()
    assert(self.m_gWriter ~= nil, "sync: Unlock of unlocked RWMutex")
    self.m_gWriter = nil
    for i = 1, #self.m_lRWaiters do
        local g = self.m_lRWaiters[i]
        goready(g)
    end
    self.m_lRWaiters = {}

    if #self.m_lWWaiters > 0 then
        local g = table.remove(self.m_lWWaiters, 1)
        goready(g)
    end
end


local Once = Infra.NewStruct('Once')

function Once:init()
    self.m_IsDone = false
    self.m_mutex = Mutex:New()
end

function Once:Do(f)
    if not self.m_IsDone then
        self.m_mutex:Lock()
        if not self.m_IsDone then
            f()
            self.m_IsDone = true
        end
        self.m_mutex:Unlock()
    end
end


local M = {}

function M.NewWaitGroup()
    return WaitGroup:New()
end

function M.NewMutex()
    return Mutex:New()
end

function M.NewRWMutex()
    return RWMutex:New()
end

function M.NewOnce()
    return Once:New()
end

return M