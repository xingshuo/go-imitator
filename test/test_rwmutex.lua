local Log = require 'log'
local Sync = require 'sync'
local Time = require 'time'

local rwMutex = Sync.NewRWMutex()
local wg = Sync.NewWaitGroup()

function runReadLock()
    Log.Print('rlock begin')
    rwMutex:RLock()
    Log.Print('fetch rlock')
    Time.Sleep(Time.Second)
    rwMutex:RUnlock()
    wg:Done()
    Log.Print('rlock done')
end

function runWriteLock()
    Log.Print('wlock begin')
    rwMutex:Lock()
    Log.Print('fetch wlock')
    Time.Sleep(2 * Time.Second)
    rwMutex:Unlock()
    wg:Done()
    Log.Print('wlock done')
end

function main()
    wg:Add(5)

    for i = 1, 2 do
        go(runWriteLock)
    end
    for i = 1, 3 do
        go(runReadLock)
    end

    wg:Wait()
end