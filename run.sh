#!/bin/sh

for filename in `ls -a test/`
do
    if ! [ -d $filename ] ;then
        suffix=${filename:0-4:4}
        if [ ".lua" == "$suffix" ] ;then
            echo =======run $filename begin===========
            lua runtime/main.lua test/$filename
        fi
    fi
done