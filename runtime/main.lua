require 'runtime.preload'

local script = ...
assert(script, 'empty script')
if script:sub(-4, -1) == '.lua' then
    script = script:sub(1, -5)
end

package.path = package.path .. ';src/?.lua'

require(script)
assert(type(main) == 'function', 'script no main function: ' .. script)

P:newMainG(main)
P:run()