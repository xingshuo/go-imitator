local delimiter = package.config:sub(1, 1)
if delimiter == '\\' then -- windows
    os.sleep = function (n)
        if n > 0 then
            os.execute("ping -n " .. tonumber(n+1) .. " localhost > NUL")
        end
    end

elseif delimiter == '/' then -- linux
    os.sleep = function (n)
        os.execute("sleep " .. tonumber(n))
    end
else
    error('unknown platform, delimiter: ' .. delimiter)
end


function panic(s)
    error('panic: ' .. tostring(s))
end

function gopark()
    coroutine.yield('SUSPEND')
end

function goready(g)
    g:setReady()
end

local Goroutine = require 'src.goroutine'
function getg()
    return Goroutine.Running()
end

local Chan = require 'src.chan'
function chan(cap)
    return Chan.New(cap)
end

function close(ch)
    ch:close()
end

local Scheduler = require 'src.scheduler'
P = Scheduler.New() -- global singleton 

function go(f)
    P:newGoroutine(f)
end