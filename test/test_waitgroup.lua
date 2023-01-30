local Log = require 'log'
local Time = require 'time'
local Sync = require 'sync'

local function worker(id)
    Log.Printf("Worker %d starting\n", id)
    Time.Sleep(Time.Second)
    Log.Printf("Worker %d done\n", id)
end

function main()
    local wg = Sync.NewWaitGroup()
    for i = 1, 5 do
        wg:Add(1)
        go(function (id)
            worker(id)
            wg:Done()
        end, i)
    end

    wg:Wait()
end