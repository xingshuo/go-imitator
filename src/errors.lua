local Infra = require 'src.infra'

local Error = Infra.NewStruct('Error')

function Error:init(s)
    self.m_ErrMsg = s
end

function Error:Error()
    return self.m_ErrMsg
end

local M = {}

function M.New(s)
    return Error:New(s)
end

return M