@echo off
chcp 65001
setlocal

rem 设置提交消息
for /f "tokens=1-4 delims=/ " %%a in ("%date%") do (
    set "year=%%a"
    set "month=%%b"
    set "day=%%c"
)
for /f "tokens=1-3 delims=:." %%a in ("%time%") do (
    set "hour=%%a"
    set "minute=%%b"
    set "second=%%c"
)
set "timestamp=%year%-!month!-!day! !hour!:!minute!:!second!"
set "commit_message=Update at %timestamp%"

echo ----------------------------------------
echo 正在同步并部署网站...
echo 提交信息: %commit_message%
echo ----------------------------------------

rem 同步远程仓库并rebase，避免产生合并提交
git pull --rebase

rem 提交所有本地修改
git add .
git commit -m "%commit_message%"

rem 推送本地修改到远程仓库
git push

echo ----------------------------------------
echo 部署完成。
echo ----------------------------------------

pause