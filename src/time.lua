local Infra = require 'src.infra'
local Goroutine = require 'src.goroutine'
local Chan = require 'src.chan'

local Timer = Infra.NewStruct('Timer')

function Timer:init(f, arg, when, ch)
    self.m_Cb = f
    self.m_Arg = arg
    self.m_When = when

    self.C = ch
end

function Timer:Stop()
    return P:delTimer(self)
end

function Timer:run()
    self.m_Cb(self.m_Arg)
end


local function sendTime(ch)
    if not ch:isFull() then
        ch:Send(os.time())
    end
end

local function goFunc(f)
    go(f)
end

local function wakeupSleep(g)
    goready(g)
end

local M = {}

M.Second = 1

function M.Sleep(sec)
    local when = os.time() + sec
    local g = Goroutine.Running()
    local t = Timer:New(wakeupSleep, g, when)
    P:addTimer(t, when)
    gopark()
end

function M.NewTimer(sec)
    local ch = Chan.New(1)
    local when = os.time() + sec
    local t = Timer:New(sendTime, ch, when, ch)
    P:addTimer(t, when)
    return t
end

function M.AfterFunc(sec, f)
    local when = os.time() + sec
    local t = Timer:New(goFunc, f, when)
    P:addTimer(t, when)
    return t
end

return M