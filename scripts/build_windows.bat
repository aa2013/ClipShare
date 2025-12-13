@echo off
call flutter build windows --release
start ..\build\windows\x64\runner\Release