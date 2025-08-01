@echo off
set "timestamp=%date% %time%"
set "commit_message=Update at %timestamp:~0,19%"
git pull
git add .
git commit -m "%commit_message%"
git push
pause