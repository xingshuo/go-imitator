
local struct_pool = {}

local base_struct = {}
base_struct.__index = base_struct

struct_pool['base_struct'] = base_struct

function base_struct:New(...)
    local o = {}
    setmetatable(o, self)
    if o.init then
        o:init(...)
    end
    return o
end

local M = {}

function M.NewStruct(clsName, parentClsName)
    assert(not struct_pool[clsName], 'redefine struct <' .. clsName .. '>')
    parentClsName = parentClsName or 'base_struct'
    local parentCls = assert(struct_pool[parentClsName], 'parent struct <' .. parentClsName .. '> no exist')

    local cls = {}
    cls.__index = cls
    struct_pool[clsName] = cls
    setmetatable(cls, parentCls)
    return cls
end

function M.GetStruct(clsName)
    local cls = assert(struct_pool[clsName], 'struct <' .. clsName .. '> no exist')
    return cls
end

return M