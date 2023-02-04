echo off

for %%f in (test\*.lua) do (
    echo =======run %%f begin===========
    lua runtime/main.lua %%f
)