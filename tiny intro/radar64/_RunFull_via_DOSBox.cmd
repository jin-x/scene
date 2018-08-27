@echo off
set name=radar64
set dir=full
set file=radar78f

dosbox\DOSBox.exe -c "mount a %dir%" -c a:\%file%.com -c exit -noautoexec -conf dosbox\%name%.conf
