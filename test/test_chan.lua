local Log = require 'log'

function main()
    local c1 = chan(0)  -- no buffer chan
    local c2 = chan(1) -- buffer chan
    assert(#c2 == 0, #c2)
    c2:Send('aaa')
    assert(#c2 == 1, #c2)

    go(function ()
        for i = 1, 5 do
            Log.Printf("send: %s begin", i)
            c1:Send(i)
            Log.Printf("send: %s done", i)
        end

        local val = c2:Recv()
        assert(val == 'aaa', val)
        assert(#c2 == 0, #c2)
    end)

    go(function ()
        for i = 1, 5 do
            Log.Printf("recv: %s begin", i)
            local j = c1:Recv()
            Log.Printf("recv: %s done", j)
        end
    end)

    Log.Print('buffer chan send blocked')
    c2:Send('bbb')
    assert(#c2 == 1, #c2)
    close(c2)
    Log.Print('buffer chan closed')
    local val, ok = c2:Recv()
    assert(val == 'bbb' and ok == true)
    val, ok = c2:Recv()
    assert(val == 0 and ok == false)
end