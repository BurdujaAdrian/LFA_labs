@echo off

echo building exe...

odin build . -out:main.exe -strict-style %1

pause
