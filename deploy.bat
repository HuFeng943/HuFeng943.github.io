@echo off
chcp 65001
setlocal enabledelayedexpansion

rem 设置提交消息
for /f "tokens=1-6 delims= " %%a in ('date /t') do (
    set "weekday=%%a"
    set "month=%%c"
    set "day=%%d"
    set "year=%%e"
)

for /f "tokens=1-4 delims=:," %%a in ('time /t') do (
    set "hour=%%a"
    set "minute=%%b"
    set "ampm=%%c"
)

set "commit_message=Update at %year%-%month%-%day% %hour%:%minute% %ampm%"

echo.
echo ====================================
echo 正在同步并部署网站...
echo 提交信息：%commit_message%
echo ====================================
echo.

git add .
git commit -m "%commit_message%"
git push

echo.
echo ====================================
echo 部署完成
echo ====================================
pause