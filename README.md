Go-imitator
====
Imitate and implement some features of golang in lua

Features
---------

* goroutine
* chan && select
* time.Timer
* sync.WaitGroup

Test
---------
```
lua runtime/main.lua test/test_chan.lua
lua runtime/main.lua test/test_select.lua
lua runtime/main.lua test/test_timer.lua
lua runtime/main.lua test/test_waitgroup.lua
...
```