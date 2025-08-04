<#
.SYNOPSIS
    博客部署脚本 - 图形界面版

.DESCRIPTION
    该脚本提供了现代化的GUI界面来完成博客部署任务：
    1. 更新并重置Git子模块
    2. 清理旧的构建文件
    3. 可视化展示文件变更
    4. 带倒计时的确认步骤
    5. 自动暂存、提交并强制推送
    6. 图形化错误处理

.NOTES
    版本: 3.0 (GUI版)
    作者: Gemini
    创建日期: 2025-08-04
#>

# 确保使用PowerShell 7+
#requires -Version 7.0

# 加载必要的程序集
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

# 全局设置
$publicPath = ".\public"
$Global:ErrorCount = 0
$Global:WarningCount = 0
$Global:CurrentStep = 0
$Global:TotalSteps = 7
$Global:ThemeList = @()

# 创建主窗体
$form = New-Object System.Windows.Forms.Form
$form.Text = "博客部署助手 v3.0"
$form.Size = New-Object System.Drawing.Size(850, 650)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# 创建标题区域
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Size = New-Object System.Drawing.Size(830, 80)
$headerPanel.Location = New-Object System.Drawing.Point(10, 10)
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "博客部署助手"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)

$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = "v3.0 (GUI版)"
$versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$versionLabel.ForeColor = [System.Drawing.Color]::White
$versionLabel.AutoSize = $true
$versionLabel.Location = New-Object System.Drawing.Point(22, 50)

$headerPanel.Controls.Add($titleLabel)
$headerPanel.Controls.Add($versionLabel)

# 创建进度显示
$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Text = "准备开始..."
$progressLabel.Location = New-Object System.Drawing.Point(20, 100)
$progressLabel.Size = New-Object System.Drawing.Size(800, 20)
$progressLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 130)
$progressBar.Size = New-Object System.Drawing.Size(800, 25)
$progressBar.Style = "Continuous"
$progressBar.ForeColor = [System.Drawing.Color]::FromArgb(0, 122, 204)

# 创建日志文本框
$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(20, 170)
$logBox.Size = New-Object System.Drawing.Size(800, 300)
$logBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$logBox.ForeColor = [System.Drawing.Color]::White
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$logBox.ReadOnly = $true
$logBox.ScrollBars = "Vertical"

# 创建状态栏
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Size = New-Object System.Drawing.Size(830, 22)
$statusBar.Location = New-Object System.Drawing.Point(0, 590)
$statusBar.SizingGrip = $false
$statusBar.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$statusBar.ForeColor = [System.Drawing.Color]::White

# 创建控制按钮
$deployButton = New-Object System.Windows.Forms.Button
$deployButton.Text = "开始部署"
$deployButton.Location = New-Object System.Drawing.Point(20, 490)
$deployButton.Size = New-Object System.Drawing.Size(120, 40)
$deployButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$deployButton.ForeColor = [System.Drawing.Color]::White
$deployButton.FlatStyle = "Flat"
$deployButton.FlatAppearance.BorderSize = 0
$deployButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$deployButton.Add_Click({ Start-Deployment })

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "取消"
$cancelButton.Location = New-Object System.Drawing.Point(160, 490)
$cancelButton.Size = New-Object System.Drawing.Size(120, 40)
$cancelButton.BackColor = [System.Drawing.Color]::FromArgb(64, 64, 64)
$cancelButton.ForeColor = [System.Drawing.Color]::White
$cancelButton.FlatStyle = "Flat"
$cancelButton.FlatAppearance.BorderSize = 0
$cancelButton.Enabled = $false
$cancelButton.Add_Click({ 
    Add-Log "操作已取消" -Color "Yellow"
    $Global:ErrorCount = 1
    $deployButton.Enabled = $true
    $cancelButton.Enabled = $false
})

$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "退出"
$exitButton.Location = New-Object System.Drawing.Point(700, 490)
$exitButton.Size = New-Object System.Drawing.Size(120, 40)
$exitButton.BackColor = [System.Drawing.Color]::FromArgb(64, 64, 64)
$exitButton.ForeColor = [System.Drawing.Color]::White
$exitButton.FlatStyle = "Flat"
$exitButton.FlatAppearance.BorderSize = 0
$exitButton.Add_Click({ $form.Close() })

# 创建变更面板
$changesPanel = New-Object System.Windows.Forms.Panel
$changesPanel.Location = New-Object System.Drawing.Point(300, 490)
$changesPanel.Size = New-Object System.Drawing.Size(380, 80)
$changesPanel.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$changesPanel.BorderStyle = "FixedSingle"
$changesPanel.Visible = $false

$changesLabel = New-Object System.Windows.Forms.Label
$changesLabel.Text = "检测到变更:"
$changesLabel.Location = New-Object System.Drawing.Point(10, 10)
$changesLabel.Size = New-Object System.Drawing.Size(360, 20)
$changesLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

$changesList = New-Object System.Windows.Forms.ListBox
$changesList.Location = New-Object System.Drawing.Point(10, 35)
$changesList.Size = New-Object System.Drawing.Size(360, 40)
$changesList.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$changesList.ForeColor = [System.Drawing.Color]::White
$changesList.BorderStyle = "None"

$changesPanel.Controls.Add($changesLabel)
$changesPanel.Controls.Add($changesList)

# 添加控件到窗体
$form.Controls.Add($headerPanel)
$form.Controls.Add($progressLabel)
$form.Controls.Add($progressBar)
$form.Controls.Add($logBox)
$form.Controls.Add($deployButton)
$form.Controls.Add($cancelButton)
$form.Controls.Add($exitButton)
$form.Controls.Add($changesPanel)
$form.Controls.Add($statusBar)

# 日志函数
function Add-Log {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colorMap = @{
        "Red"    = [System.Drawing.Color]::FromArgb(255, 100, 100)
        "Green"  = [System.Drawing.Color]::FromArgb(100, 255, 100)
        "Yellow" = [System.Drawing.Color]::FromArgb(255, 255, 100)
        "Blue"   = [System.Drawing.Color]::FromArgb(100, 180, 255)
        "White"  = [System.Drawing.Color]::White
    }
    
    $logBox.SelectionStart = $logBox.TextLength
    $logBox.SelectionLength = 0
    $logBox.SelectionColor = $colorMap[$Color]
    $logBox.AppendText("$(Get-Date -Format 'HH:mm:ss') - $Message`r`n")
    $logBox.ScrollToCaret()
    
    # 更新状态栏
    $statusBar.Text = "错误: $Global:ErrorCount | 警告: $Global:WarningCount | 主题: $($Global:ThemeList.Count)"
    $form.Update()
}

# 更新进度
function Update-Progress {
    param(
        [string]$Message,
        [int]$Step = -1
    )
    
    if ($Step -ge 0) {
        $Global:CurrentStep = $Step
        $percent = [Math]::Round(($Global:CurrentStep / $Global:TotalSteps) * 100)
        $progressBar.Value = $percent
    }
    
    $progressLabel.Text = $Message
    $form.Update()
}

# 执行步骤
function Invoke-Step {
    param(
        [string]$StepName,
        [scriptblock]$Action,
        [scriptblock]$SuccessAction
    )
    
    Add-Log "执行: $StepName" -Color "Blue"
    Update-Progress $StepName
    
    try {
        $output = & $Action 2>&1
        $isSuccess = ($LASTEXITCODE -eq 0)
        
        if ($isSuccess) {
            Add-Log "✓ $StepName 成功" -Color "Green"
            if ($SuccessAction) {
                & $SuccessAction $output
            }
        } else {
            Add-Log "✗ $StepName 失败" -Color "Red"
            $Global:ErrorCount++
            Resolve-Error -ErrorOutput ($output | Out-String) -StepName $StepName
        }
        
        return $isSuccess
    }
    catch {
        Add-Log "✗ $StepName 异常: $($_.Exception.Message)" -Color "Red"
        $Global:ErrorCount++
        return $false
    }
}

# 错误处理
function Resolve-Error {
    param(
        [string]$ErrorOutput,
        [string]$StepName
    )
    
    $gitErrorSolutions = @{
        "not a git repository" = "当前目录不是一个Git仓库"
        "No url found for submodule path" = "在.gitmodules中找不到子模块URL"
        "repository .* not found" = "远程仓库地址错误或不存在"
        "could not read|Connection was reset" = "网络连接异常"
        "pathspec .* did not match any files" = "Git未能找到指定文件或路径"
        "could not lock config file" = "无法锁定Git配置文件"
        "local changes .* would be overwritten" = "有未提交的本地修改会冲突"
        "Failed to merge|CONFLICT" = "合并失败，存在代码冲突"
        "Updates were rejected" = "推送被拒绝，请先执行git pull"
        "Permission denied|Authentication failed" = "权限不足或身份验证失败"
    }
    
    $fileErrorSolutions = @{
        "Access to the path" = "权限不足"
        "because it is being used by another process" = "文件或文件夹正被其他程序占用"
        "Could not find a part of the path" = "路径不存在"
    }
    
    $foundSolution = $false
    
    # 检查Git错误
    foreach ($pattern in $gitErrorSolutions.Keys) {
        if ($ErrorOutput -match $pattern) {
            Add-Log "  原因: $($gitErrorSolutions[$pattern])" -Color "Yellow"
            $foundSolution = $true
            break
        }
    }
    
    # 检查文件系统错误
    if (-not $foundSolution) {
        foreach ($pattern in $fileErrorSolutions.Keys) {
            if ($ErrorOutput -match $pattern) {
                Add-Log "  原因: $($fileErrorSolutions[$pattern])" -Color "Yellow"
                $foundSolution = $true
                break
            }
        }
    }
    
    # 未知错误
    if (-not $foundSolution) {
        Add-Log "  未知错误: $($ErrorOutput.Trim())" -Color "Yellow"
    }
}

# 确认部署
function Confirm-Deployment {
    $changes = git status --porcelain
    $branchName = git rev-parse --abbrev-ref HEAD
    $hasChanges = $changes -ne $null
    
    # 显示变更
    if ($hasChanges) {
        $changesPanel.Visible = $true
        $changesList.Items.Clear()
        $changes | ForEach-Object { $changesList.Items.Add($_) }
        
        # 分支状态检查
        if ($branchName -ne "main") {
            Add-Log "警告: 当前分支 '$branchName' (应为 'main')" -Color "Yellow"
            $Global:WarningCount++
        }
        
        $remoteStatus = git status -sb
        if ($remoteStatus -match "ahead") {
            Add-Log "警告: 本地分支领先于远程分支" -Color "Yellow"
            $Global:WarningCount++
        }
        if ($remoteStatus -match "behind") {
            Add-Log "警告: 本地分支落后于远程分支，强制推送将覆盖远程提交!" -Color "Yellow"
            $Global:WarningCount++
        }
        
        # 创建确认对话框
        $result = [System.Windows.Forms.MessageBox]::Show(
            "即将提交所有变更并强制覆盖远程仓库！`n`n共检测到 $($changes.Count) 个变更。`n是否继续？",
            "确认部署",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        $changesPanel.Visible = $false
        return ($result -eq "Yes")
    }
    else {
        Add-Log "没有检测到文件变更，跳过确认步骤" -Color "Green"
        return $true
    }
}

# 倒计时确认
function Confirm-WithCountdown {
    param(
        [int]$Seconds = 5
    )
    
    $deployButton.Enabled = $false
    $cancelButton.Enabled = $true
    
    for ($i = $Seconds; $i -gt 0; $i--) {
        Update-Progress "将在 $i 秒后自动继续 (按取消按钮停止)..."
        
        # 检查取消请求
        if (-not $cancelButton.Enabled) {
            Add-Log "操作已取消" -Color "Yellow"
            return $false
        }
        
        Start-Sleep -Seconds 1
    }
    
    $cancelButton.Enabled = $false
    return $true
}

# 部署流程
function Start-Deployment {
    $deployButton.Enabled = $false
    $logBox.Clear()
    $Global:ErrorCount = 0
    $Global:WarningCount = 0
    $Global:CurrentStep = 0
    $Global:ThemeList = @()
    
    Add-Log "=== 博客部署流程开始 ===" -Color "Blue"
    
    # 步骤1: 更新主题
    Update-Progress "步骤 1/3: 更新和清理主题" -Step 1
    $updateSuccess = Invoke-Step -StepName "拉取远程主题更新" -Action {
        git submodule update --remote --init --recursive
    }
    
    if ($updateSuccess) {
        Invoke-Step -StepName "重置所有主题文件" -Action {
            git submodule foreach --recursive "git reset --hard && git clean -fdx"
        } -SuccessAction {
            param($output)
            $matches = [regex]::Matches($output, "Entering '(themes/.*?)'")
            $Global:ThemeList = $matches | ForEach-Object { $_.Groups[1].Value }
            Add-Log "  已处理主题: $($Global:ThemeList -join ', ')" -Color "Green"
        }
    }
    
    # 步骤2: 清理构建文件
    Update-Progress "步骤 2/3: 清理旧的构建产物" -Step 3
    if (Test-Path $publicPath) {
        Invoke-Step -StepName "删除本地构建文件夹" -Action {
            Remove-Item -Path $publicPath -Recurse -Force -ErrorAction Stop
        }
    }
    else {
        Add-Log "public 文件夹不存在，跳过清理" -Color "Green"
    }
    
    # 步骤3: 确认部署
    Update-Progress "步骤 3/3: 提交并部署" -Step 4
    if (-not (Confirm-WithCountdown -Seconds 5)) { return }
    
    if (-not (Confirm-Deployment)) {
        Add-Log "部署已取消" -Color "Yellow"
        $deployButton.Enabled = $true
        return
    }
    
    # 步骤4: 添加变更
    $changes = git status --porcelain
    if ($changes) {
        Update-Progress "添加变更到暂存区" -Step 5
        Invoke-Step -StepName "添加所有变更" -Action {
            git add .
        }
        
        # 步骤5: 提交变更
        Update-Progress "提交变更到本地仓库" -Step 6
        $commitMessage = "Deploy: content update at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')"
        Invoke-Step -StepName "创建提交" -Action {
            git commit -m $commitMessage
        } -SuccessAction {
            Add-Log "  提交信息: $commitMessage" -Color "Green"
        }
    }
    else {
        Add-Log "没有变更需要提交" -Color "Green"
    }
    
    # 步骤6: 强制推送
    Update-Progress "强制推送到远程仓库" -Step 7
    Invoke-Step -StepName "强制推送" -Action {
        git push --force
    }
    
    # 最终状态
    if ($Global:ErrorCount -gt 0) {
        Add-Log "任务完成，但遇到 $Global:ErrorCount 个错误" -Color "Red"
        [System.Windows.Forms.MessageBox]::Show(
            "部署完成，但有 $Global:ErrorCount 个错误发生！",
            "完成",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
    else {
        Add-Log "🎉 所有任务已成功完成！" -Color "Green"
        [System.Windows.Forms.MessageBox]::Show(
            "部署成功完成！",
            "完成",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    
    $deployButton.Enabled = $true
}

# 显示窗体
Add-Log "就绪 - 点击'开始部署'按钮开始流程" -Color "Green"
$form.ShowDialog()