@echo off
Forfiles.exe -p C:\inetpub\logs\LogFiles\W3SVC1 -m *.log -d -14 -c "Cmd.exe /C del @path"
Forfiles.exe -p C:\inetpub\logs\LogFiles\W3SVC2 -m *.log -d -14 -c "Cmd.exe /C del @path"