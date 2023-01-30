local Infra = require 'src.infra'
local CQueue = require 'src.cqueue'
local Goroutine = require 'src.goroutine'

local tinsert = table.insert
local tremove = table.remove

-- buffer chan
local Chan = Infra.NewStruct('Chan')

function Chan:init(cap)
    self.m_MQ = CQueue.New(cap)
    self.m_SendQ = {} -- goroutine list of send waiters
    self.m_RecvQ = {} -- goroutine list of recv waiters
    self.m_Closed = false
end

-- equal to range chan
function Chan:__pairs()
    return function ()
        local val, ok = self:Recv()
        if not ok then
            return
        end

        return val, ok
    end
end

-- equal to len(chan)
function Chan:__len()
    return self.m_MQ:Size()
end

function Chan:capacity()
    return self.m_MQ:Capacity()
end

function Chan:isFull()
    return self.m_MQ:IsFull()
end

function Chan:isEmpty()
    return self.m_MQ:IsEmpty()
end

function Chan:_pushRecvQ(g)
    tinsert(self.m_RecvQ, g)
end

function Chan:_delFromRecvQ(g)
    for i, gr in pairs(self.m_RecvQ) do
        if gr == g then
            tremove(self.m_RecvQ, i)
            return true
        end
    end
    return false
end

function Chan:Send(val)
    if self.m_Closed then
        panic('send on closed channel')
    end
    if self.m_MQ:IsFull() then
        repeat
            local g = Goroutine.Running()
            tinsert(self.m_SendQ, g)
            gopark()
            if self.m_Closed then
                panic('send on closed channel')
            end
        until not self.m_MQ:IsFull()
    end

    self.m_MQ:Push(val)
    if #self.m_RecvQ > 0 then
        local g = tremove(self.m_RecvQ, 1)
        goready(g)
    end
end

-- return: value, ok
function Chan:Recv()
    if self.m_MQ:IsEmpty() then
        repeat
            if self.m_Closed then
                return 0, false
            end
            local g = Goroutine.Running()
            tinsert(self.m_RecvQ, g)
            gopark()
        until not self.m_MQ:IsEmpty()
    end

    local val = self.m_MQ:Pop()
    if #self.m_SendQ > 0 then
        local g = tremove(self.m_SendQ, 1)
        goready(g)
    end

    return val, true
end

function Chan:isReadable()
    return self.m_MQ:Size() > 0
end

function Chan:isClosed()
    return self.m_Closed
end

function Chan:close()
    if self.m_Closed then
        panic('close of closed channel')
    end
    self.m_Closed = true

    for _, g in pairs(self.m_SendQ) do
        goready(g)
    end
    self.m_SendQ = {}

    for _, g in pairs(self.m_RecvQ) do
        goready(g)
    end
    self.m_RecvQ = {}
end


local NoBufferChan = Infra.NewStruct('NoBufferChan')

function NoBufferChan:init()
    self.m_SendQ = {} -- sudog list of send waiters
    self.m_RecvQ = {} -- goroutine list of recv waiters
    self.m_Closed = false
end

function NoBufferChan:__pairs()
    return function ()
        local val, ok = self:Recv()
        if not ok then
            return
        end

        return val, ok
    end
end

function NoBufferChan:__len()
    return 0
end

function NoBufferChan:capacity()
    return 0
end

function NoBufferChan:isFull()
    return true
end

function NoBufferChan:isEmpty()
    return true
end

function NoBufferChan:_pushRecvQ(g)
    tinsert(self.m_RecvQ, g)
end

function NoBufferChan:_delFromRecvQ(g)
    for i, gr in pairs(self.m_RecvQ) do
        if gr == g then
            tremove(self.m_RecvQ, i)
            return true
        end
    end
    return false
end

function NoBufferChan:Send(val)
    if self.m_Closed then
        panic('send on closed channel')
    end
    local sudog = {
        g = Goroutine.Running(),
        val = val,
    }
    tinsert(self.m_SendQ, sudog)
    if #self.m_RecvQ > 0 then
        local g = tremove(self.m_RecvQ, 1)
        goready(g)
    end

    gopark()
end

-- return: value, ok
function NoBufferChan:Recv()
    if #self.m_SendQ == 0 then
        repeat
            if self.m_Closed then
                return 0, false
            end
            tinsert(self.m_RecvQ, Goroutine.Running())
            gopark()
        until #self.m_SendQ > 0
    end

    local sudog = tremove(self.m_SendQ, 1)
    local g = sudog.g
    local val = sudog.val

    goready(g)

    return val, true
end

function NoBufferChan:isReadable()
    return #self.m_SendQ > 0
end

function NoBufferChan:isClosed()
    return self.m_Closed
end

function NoBufferChan:close()
    if self.m_Closed then
        panic('close of closed channel')
    end
    self.m_Closed = true

    for _, sudog in pairs(self.m_SendQ) do
        goready(sudog.g)
    end
    self.m_SendQ = {}

    for _, g in pairs(self.m_RecvQ) do
        goready(g)
    end
    self.m_RecvQ = {}
end


local M = {}

function M.New(cap)
    if cap > 0 then
        return Chan:New(cap)
    else
        return NoBufferChan:New()
    end
end

-- Notice: only listen chans recv
function M.Select(lchans, noblocking)
    local n = #lchans
    if n == 0 then
        return
    end

    repeat
        for i = 1, n do
            local ch = lchans[i]
            if ch:isReadable() then
                return ch
            end
            if ch:isClosed() then
                return ch
            end
        end
        if noblocking then
            return
        end
        local g = Goroutine.Running()
        for i = 1, n do
            local ch = lchans[i]
            ch:_pushRecvQ(g)
        end

        gopark()
        for i = 1, n do
            local ch = lchans[i]
            ch:_delFromRecvQ(g)
        end
    until false
end

return M