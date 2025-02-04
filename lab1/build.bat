@echo off

echo building exe...

odin build . -out:main.exe -o:minimal -strict-style %1

pause
