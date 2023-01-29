local Time = require 'time'
local Log = require 'log'

function main()
    go(function ()
        Log.Print('start timer begin:')
        local t = Time.NewTimer(2 * Time.Second)
        local ts = t.C:Recv() -- equal to: <- t.C
        Log.Printf('timer timeout at %s', ts)
    end)

    go(function ()
        Log.Print('start after func begin:')
        Time.AfterFunc(4, function ()
            Log.Print('run after func')
        end)
    end)

    local t = Time.NewTimer(3 * Time.Second)
    go(function ()
        Log.Print('wait stopped timer begin:')
        t.C:Recv()
        Log.Print('wait stopped timer done')
    end)
    t:Stop()

    Log.Print('sleep begin:')
    Time.Sleep(5 * Time.Second)
    Log.Print('sleep done')
end