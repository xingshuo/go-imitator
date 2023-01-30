local Time = require 'time'
local Log = require 'log'

function main()
    local t = Time.NewTimer(3 * Time.Second)
    local c1 = chan(0)
    local c2 = chan(1)
    local ch = Select({t.C, c1, c2}, true)
    assert(ch == nil)
    c2:Send(100)
    ch = Select({t.C, c1, c2})
    assert(ch == c2)
    assert(c2:Recv() == 100)

    go(function ()
        c1:Send('abc')
        Log.Print('c1 send done')
    end)
    Time.AfterFunc(5 * Time.Second, function ()
        close(c2)
        Log.Print('c2 closed')
    end)

    Log.Print('test blocking Select begin')
    while true do
        ch = Select({t.C, c1, c2})
        if ch == c1 then
            Log.Printf('recv %s from c1', c1:Recv())
        elseif ch == t.C then
            Log.Printf('recv %s from timer', t.C:Recv())
        else
            assert(ch == c2)
            Log.Print('quit Select loop')
            break
        end
    end
end