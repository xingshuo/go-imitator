
local M = {}

local _sformat = string.format

function M.Printf(a, ...)
    local msg = _sformat(a, ...)
    print(_sformat("[%s %s %s] %s", os.date("%Y/%m/%d %H:%M:%S"), getg(), coroutine.running(), msg))
end

function M.Print(...)
    local msg = table.concat({...}, ' ')
    print(_sformat("[%s %s %s] %s", os.date("%Y/%m/%d %H:%M:%S"), getg(), coroutine.running(), msg))
end

return M