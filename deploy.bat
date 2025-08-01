@echo off
chcp 65001
setlocal enabledelayedexpansion

rem 获取时间
set "HH=%time:~0,2%"
set "Min=%time:~3,2%"
set "Sec=%time:~6,2%"

rem 组合成提交消息
set "commit_message=Update at %date% %HH%:%Min%:%Sec%"

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