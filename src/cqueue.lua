local Infra = require 'src.infra'

-- Circular Queue
local Queue = Infra.NewStruct('Queue')

function Queue:init(cap)
    assert(cap and cap > 0, 'circle queue must specify capacity')
    self.m_Capacity = cap
    self.m_Size = 0
    self.m_Head = 1
    self.m_Tail = 0
    self.m_Datas = {}
end

function Queue:_getNextPos(pos)
    pos = pos + 1
    if pos > self.m_Capacity then
        pos = 1
    end
    return pos
end

function Queue:Push( v )
    self.m_Tail = self:_getNextPos(self.m_Tail)
    self.m_Datas[self.m_Tail] = v
    if self.m_Size < self.m_Capacity then
        self.m_Size = self.m_Size + 1
    else
        self.m_Head = self:_getNextPos(self.m_Head)
    end
end

function Queue:Pop()
    if self.m_Size <= 0 then
        return nil
    end

    local head = self.m_Head
    local v = self.m_Datas[head]
    self.m_Datas[head] = nil
    self.m_Head = self:_getNextPos(head)
    self.m_Size = self.m_Size - 1
    return v
end

function Queue:Top()
    if self.m_Size <= 0 then
        return nil
    end

    return self.m_Datas[self.m_Head]
end

function Queue:IsEmpty()
    return self.m_Size <= 0
end

function Queue:IsFull()
    return self.m_Size >= self.m_Capacity
end

function Queue:Size()
    return self.m_Size
end

function Queue:Capacity()
    return self.m_Capacity
end

local M = {}

function M.New(capacity)
	return Queue:New(capacity)
end

return M