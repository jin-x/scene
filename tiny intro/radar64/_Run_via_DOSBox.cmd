@echo off
set name=radar64
set dir=.
set file=%name%

dosbox\DOSBox.exe -c "mount a %dir%" -c a:\%file%.com -c exit -noautoexec -conf dosbox\%name%.conf
