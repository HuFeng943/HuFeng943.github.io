# 将当前目录下的所有修改提交并推送到 GitHub Pages

# 获取当前日期和时间，并格式化
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$commitMessage = "Update at $timestamp"

Write-Host "----------------------------------------"
Write-Host "正在同步并部署网站..."
Write-Host "提交信息: $commitMessage"
Write-Host "----------------------------------------"

# 同步远程仓库并 rebase，避免产生合并提交
git pull --rebase

# 提交所有本地修改
git add .
git commit -m $commitMessage

# 推送本地修改到远程仓库
git push

Write-Host "----------------------------------------"
Write-Host "部署完成"
Write-Host "----------------------------------------"

# 暂停，等待用户按键
Read-Host "按任意键退出"