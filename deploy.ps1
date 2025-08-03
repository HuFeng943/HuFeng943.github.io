# 先更新下主题
Write-Host "----------------------------------------"
Write-Host "正在更新主题文件..."
Write-Host "----------------------------------------"
git submodule update --remote # 更新更新下主题
git submodule foreach --recursive "git reset --hard && git clean -fdx" # 删掉多余的主题文件
# 将当前目录下的所有修改提交并推送到 GitHub Pages
Write-Host "----------------------------------------"
Write-Host "正在删除本地构建文件..."
Write-Host "----------------------------------------"
Remove-Item -Path ".\public" -Recurse -Force -ErrorAction SilentlyContinue  # 删除 public 目录
# 获取当前日期和时间，并格式化
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$commitMessage = "Update at $timestamp"

Write-Host "----------------------------------------"
Write-Host "正在同步并部署网站..."
Write-Host "提交信息: $commitMessage"
Write-Host "----------------------------------------"
git add . # 把所有修改都添加到暂存区
git pull --rebase # 同步远程仓库并 rebase，避免产生合并提交
git commit -m $commitMessage
# 推送本地修改到远程仓库
git push
Write-Host "----------------------------------------"
Write-Host "部署完成"
Write-Host "----------------------------------------"
# 暂停
Read-Host "回车键继续..."