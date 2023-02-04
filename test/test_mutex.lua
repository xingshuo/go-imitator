local Log = require 'log'
local Sync = require 'sync'
local Infra = require 'infra'

local Container = Infra.NewStruct('Container')

function Container:init(m)
    self.mu = Sync.NewMutex()
    self.counters = m
end

function Container:inc(name)
    self.mu:Lock()
    self.counters[name] = self.counters[name] + 1
    self.mu:Unlock()
end

function main()
    local c = Container:New({a = 0, b = 0})
    local wg = Sync.NewWaitGroup()
    local function doIncrement(name, n)
        for i = 1, n do
            c:inc(name)
        end
        wg:Done()
    end

    wg:Add(3)
    go(doIncrement, 'a', 10000)
    go(doIncrement, 'a', 10000)
    go(doIncrement, 'b', 10000)

    wg:Wait()
    assert(c.counters['a'] == 20000)
    assert(c.counters['b'] == 10000)
    Log.Printf('map [a:%d, b:%d]', c.counters['a'], c.counters['b'])
end