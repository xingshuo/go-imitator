
local M = {}

local _sformat = string.format
local _tconcat = table.concat
local coroutine = coroutine

function M.Printf(a, ...)
    local msg = _sformat(a, ...)
    print(_sformat("[%s %s %s] %s", os.date("%Y/%m/%d %H:%M:%S"), getg(), coroutine.running(), msg))
end

function M.Print(...)
    local msg = _tconcat({...}, ' ')
    print(_sformat("[%s %s %s] %s", os.date("%Y/%m/%d %H:%M:%S"), getg(), coroutine.running(), msg))
end

return M