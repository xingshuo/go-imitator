local Log = require 'log'
local Sync = require 'sync'
local Time = require 'time'

local config = {
    counter = 0,
}

local once = Sync.NewOnce()

function main()
    local wg = Sync.NewWaitGroup()
    wg:Add(10)
    for i = 1, 10 do
        go(function ()
            once:Do(function ()
                config.counter = config.counter + 1
                Time.Sleep(2 * Time.Second)
            end)
            wg:Done()
        end)
    end

    wg:Wait()
    assert(config.counter == 1, config.counter)
end