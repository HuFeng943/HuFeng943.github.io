<#
.SYNOPSIS
    一个用于自动化部署博客的增强版PowerShell脚本。

.DESCRIPTION
    该脚本旨在提供一个美观、高效且用户友好的界面来完成以下任务：
    1. 更新并重置Git子模块（例如Hugo主题）。
    2. 清理旧的构建文件（public文件夹）。
    3. 以清晰的格式展示待提交的文件变更。
    4. 提供一个带倒计时的确认步骤，防止误操作。
    5. 自动暂存、提交并强制推送到远程仓库。
    6. 对常见的Git和文件系统错误进行智能识别，并提供人性化的中文解决方案。

.NOTES
    版本: 2.0
    作者: Gemini (为你优化)
    创建日期: 2025-08-04
#>

# --- 全局设置 ---

# 1. 控制台输出编码设为UTF-8，保证中文字符和图标正确显示
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 2. 定义ANSI转义码，用于彩色输出
#    使用更具语义的变量名
$Color = @{
    Error   = "`e[91m" # 红色 (CR)
    Success = "`e[92m" # 绿色 (CG)
    Warning = "`e[93m" # 黄色 (CY)
    Info    = "`e[97m" # 白色 (CW)
    Reset   = "`e[0m"   # 重置 (RC)
}

# 3. 全局状态变量
$Global:ErrorCount = 0   # 记录脚本执行期间的错误总数
$Global:WarningCount = 0 # 记录警告总数
$publicPath = ".\public" # 博客构建输出目录

# --- 核心功能函数 ---

#
# 函数: Show-Banner
# 功能: 显示一个漂亮的脚本标题。
#
function Show-Banner {
    Write-Host "${Color.Success}===================================================${Color.Reset}"
    Write-Host "${Color.Success}  🚀  全自动博客部署脚本 v2.0 (Gemini 优化版) ${Color.Reset}"
    Write-Host "${Color.Success}===================================================${Color.Reset}"
    Write-Host
}

#
# 函数: Invoke-Step
# 功能: 执行一个操作步骤，并统一处理输出、成功/失败状态和错误。
# 这是取代原脚本复杂输出逻辑的核心。
#
function Invoke-Step {
    param(
        [Parameter(Mandatory=$true)]
        [string]$StepName,

        [Parameter(Mandatory=$true)]
        [scriptblock]$Action,
        
        [Parameter(Mandatory=$false)]
        [scriptblock]$SuccessAction # 成功后可选的额外操作
    )

    Write-Host -NoNewline "  ${Color.Info}○ ${StepName}... ${Color.Reset}"
    
    # 执行核心操作，并将所有输出流（包括错误）重定向到$output
    $output = & $Action 2>&1
    $isSuccess = ($LASTEXITCODE -eq 0)

    # 清除当前行并重新输出结果
    Write-Host "`r" -NoNewline
    if ($isSuccess) {
        Write-Host "  ${Color.Success}✓ ${StepName}  ✅ ${Color.Reset}"
        if ($null -ne $SuccessAction) {
            # 如果成功并且有后续操作，则执行
            & $SuccessAction $output
        }
    } else {
        Write-Host "  ${Color.Error}✗ ${StepName}  ❌ ${Color.Reset}"
        $Global:ErrorCount++
        Resolve-Error -InputObject $output -SourceName $StepName
    }
    
    return $isSuccess
}

#
# 函数: Resolve-Error
# 功能: 智能分析错误输出，判断是Git错误还是其他错误，并调用相应的处理函数。
#
function Resolve-Error {
    param(
        [Parameter(Mandatory=$true)]
        $InputObject,
        [string]$SourceName = "未知操作"
    )

    $errorString = $InputObject | Out-String

    if ($errorString -match "git" -or $SourceName -match "Git") {
        Resolve-GitError -ErrorOutput $errorString
    } else {
        Resolve-FileSystemError -ErrorOutput $errorString
    }
}

#
# 函数: Resolve-GitError
# 功能: 增强版的Git错误解析器，提供更全面的中文解释和建议。
#
function Resolve-GitError {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorOutput
    )

    # 将常见的Git错误信息和对应的中文解决方案存储在哈希表中
    $gitErrorSolutions = @{
        "not a git repository"                                = "当前目录不是一个Git仓库，请在正确的项目根目录下运行脚本。"
        "No url found for submodule path"                     = "在 .gitmodules 文件中找不到子模块的URL，请检查配置是否正确。"
        "repository .* not found"                             = "远程仓库地址错误或不存在，也可能是私有仓库没有访问权限。"
        "branch .* not found"                                 = "指定的分支或主题不存在于远程仓库中。"
        "could not read|Connection was reset|Empty reply from server|SSL_ERROR_SYSCALL|The remote end hung up unexpectedly|Connection timed out" = "网络连接异常。无法连接到远程仓库，请检查你的网络、VPN或代理设置。"
        "fatal: Unable to fetch|fatal: Unable to fetch in submodule" = "获取远程更新失败，通常是网络问题或远程仓库地址不正确。"
        "pathspec .* did not match any files"                 = "Git未能找到你指定的文件或路径，请检查 `git add` 的目标是否正确。"
        "A branch named .* already exists"                    = "该分支名已存在，无法创建同名分支。"
        "You are not currently on a branch"                   = "你正处于 'detached HEAD' (游离头)状态，请先执行 `git checkout <分支名>` 切换到一个分支。"
        "could not lock config file"                          = "无法锁定Git配置文件（.git/config.lock），可能是权限不足或有其他Git进程正在运行。"
        "You have not told me your name and email"            = "尚未配置Git的用户名和邮箱。请执行 `git config --global user.name 'Your Name'` 和 `git config --global user.email 'you@example.com'`。"
        "local changes .* would be overwritten"               = "有未提交的本地修改会与远程内容冲突。请先使用 `git stash` 暂存或 `git commit` 提交你的修改。"
        "Failed to merge|CONFLICT"                            = "合并失败，存在代码冲突。请手动解决冲突后再提交。"
        "Updates were rejected because the tip .* is behind"  = "推送被拒绝，因为远程仓库有你本地没有的更新。请先执行 `git pull` 合并远程变更。"
        "error: failed to push some refs to"                  = "推送失败，这是一个通用错误，请检查上面的详细信息或远程仓库状态。"
        "Permission denied|Authentication failed|403"         = "权限不足或身份验证失败。请检查你的SSH密钥、Personal Access Token或账户密码是否正确且有权限。"
        "index file is corrupt"                               = "Git索引文件(.git/index)已损坏。请尝试删除后执行 `git reset` 来重建。"
        "pack has bad object"                                 = "Git数据包中的对象损坏，可能需要进行仓库修复或重新克隆。"
        "HTTP 413|Request Entity Too Large"                   = "提交的文件过大，超出了服务器限制。请检查是否有大文件未被 `gitignore` 规则忽略。"
        "cannot lock ref"                                     = "无法锁定引用，通常意味着有另一个Git操作正在进行中，或者上次操作异常退留下了锁文件(.git/refs/.../*.lock)。"
    }

    $foundError = $false
    foreach ($pattern in $gitErrorSolutions.Keys) {
        if ($ErrorOutput -match $pattern) {
            Write-Host "    ${Color.Error}↳ 错误原因: $($gitErrorSolutions[$pattern])${Color.Reset}"
            $foundError = $true
            break # 找到第一个匹配的就跳出
        }
    }

    if (-not $foundError) {
        Write-Host "    ${Color.Error}↳ 捕获到未知Git错误:${Color.Reset}"
        # 只显示简洁的错误信息，而不是完整的堆栈跟踪
        ($ErrorOutput -split "`n") | ForEach-Object { if ($_.Trim()) { Write-Host "      ${Color.Warning}$_${Color.Reset}" } }
    }
}

#
# 函数: Resolve-FileSystemError
# 功能: 解析文件系统相关的错误，例如删除文件夹失败。
#
function Resolve-FileSystemError {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorOutput
    )
    
    $fileErrorSolutions = @{
        "Access to the path"                               = "权限不足，脚本没有足够的权限删除或修改该文件/文件夹。"
        "because it is being used by another process"      = "文件或文件夹正被其他程序占用（例如VS Code、hugo server），请关闭相关程序后重试。"
        "Could not find a part of the path"                = "路径不存在，可能在执行删除时已经被移动或删除了。"
    }

    $foundError = $false
    foreach ($pattern in $fileErrorSolutions.Keys) {
        if ($ErrorOutput -match $pattern) {
            Write-Host "    ${Color.Warning}↳ 失败原因: $($fileErrorSolutions[$pattern])${Color.Reset}"
            $foundError = $true
            break
        }
    }

    if (-not $foundError) {
        Write-Host "    ${Color.Warning}↳ 捕获到未知文件系统错误: $ErrorOutput ${Color.Reset}"
    }
}


#
# 函数: Confirm-Deployment
# 功能: 显示Git状态并请求用户确认，包含倒计时。
#
function Confirm-Deployment {
    Write-Host
    Write-Host "${Color.Info}-------------------[ 变更审查 ]-------------------${Color.Reset}"
    
    $statusOutput = git status --porcelain # 使用更易于脚本解析的格式
    $hasChanges = $false

    if ($statusOutput) {
        $hasChanges = $true
        Write-Host "  检测到以下文件变更:"
        $statusOutput | ForEach-Object {
            $line = $_.Trim()
            $fileStatus = $line.Substring(0, 2)
            $filePath = $line.Substring(3)
            switch -Regex ($fileStatus) {
                "^\?\?" { Write-Host "    ${Color.Success}新增: $filePath ${Color.Reset}" }
                "^ M"  { Write-Host "    ${Color.Warning}修改: $filePath ${Color.Reset}" }
                "^ D"  { Write-Host "    ${Color.Error}删除: $filePath ${Color.Reset}" }
                default { Write-Host "    ${Color.Info}其他: $line ${Color.Reset}" }
            }
        }
    } else {
        Write-Host "  ${Color.Success}工作区非常干净，没有检测到任何文件变更。${Color.Reset}"
    }

    # 检查分支状态
    $branchName = git rev-parse --abbrev-ref HEAD
    if ($branchName -ne "main") {
        Write-Host "  ${Color.Warning}警告: 当前不在 'main' 分支，而是 '$branchName'。${Color.Reset}"
        $Global:WarningCount++
    }
    
    $remoteStatus = git status -sb # -sb for short branch status
    if ($remoteStatus -match "ahead") {
        Write-Host "  ${Color.Warning}警告: 本地分支领先于远程分支。${Color.Reset}"
        $Global:WarningCount++
    }
    if ($remoteStatus -match "behind") {
        Write-Host "  ${Color.Warning}警告: 本地分支落后于远程分支，强制推送将覆盖远程提交！${Color.Reset}"
        $Global:WarningCount++
    }
    
    Write-Host "${Color.Info}--------------------------------------------------${Color.Reset}"
    Write-Host
    
    if (-not $hasChanges) {
        Write-Host "${Color.Success}由于没有变更，脚本将仅执行主题更新和同步，无需创建新的提交。${Color.Reset}"
        # 即使没有变更，也允许用户确认是否要继续执行推送（可能为了触发某些CI/CD）
    }

    Write-Host "${Color.Warning}确认执行部署吗？这将提交所有变更并强制覆盖远程仓库！${Color.Reset}"
    $timeoutSeconds = 5
    for ($i = $timeoutSeconds; $i -gt 0; $i--) {
        Write-Host -NoNewline "`r  将在 ${Color.Success}$i${Color.Reset} 秒后自动继续，按 'N' 键可取消..."
        if ([Console]::KeyAvailable) {
            $key = [System.Console]::ReadKey($true)
            if ($key.KeyChar -eq 'n' -or $key.KeyChar -eq 'N') {
                Write-Host "`r  ${Color.Error}用户手动取消操作，脚本已退出。               ${Color.Reset}"
                exit
            }
        }
        Start-Sleep -Seconds 1
    }
    # 清理倒计时那一行
    Write-Host "`r                                                              `r"
    return $hasChanges
}


# --- 脚本主流程 ---

Show-Banner

# 步骤 1: 更新主题（Git子模块）
Write-Host "${Color.Info}步骤 1/3: 更新和清理主题 (Git Submodules)${Color.Reset}"
$updateSuccess = Invoke-Step -StepName "拉取远程主题更新" -Action { git submodule update --remote --init --recursive }
if ($updateSuccess) {
    Invoke-Step -StepName "重置所有主题文件" -Action { git submodule foreach --recursive "git reset --hard && git clean -fdx" } `
                -SuccessAction { param($output) 
                    $themeList = ([regex]::Matches($output, "Entering '(themes/.*?)'") | ForEach-Object { $_.Groups[1].Value }) -join ", "
                    if ($themeList) { Write-Host "    ${Color.Info}↳ 已处理主题: $themeList ${Color.Reset}" }
                }
}
Write-Host

# 步骤 2: 清理旧的构建文件
Write-Host "${Color.Info}步骤 2/3: 清理旧的构建产物 (public 文件夹)${Color.Reset}"
if (Test-Path $publicPath) {
    Invoke-Step -StepName "删除本地构建文件夹" -Action { Remove-Item -Path $publicPath -Recurse -Force -ErrorAction Stop }
} else {
    Write-Host "  ${Color.Success}✓ 无需清理，'public' 文件夹不存在。 ✅ ${Color.Reset}"
}
Write-Host

# 步骤 3: 确认、提交与部署
# 首先，审查变更并等待用户确认
$hasFileChanges = Confirm-Deployment

# 然后，执行部署
Write-Host "${Color.Info}步骤 3/3: 提交并部署到远程仓库${Color.Reset}"
$commitMessage = "Deploy: content update at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')"

# 只有在有文件变动时才执行add和commit
if ($hasFileChanges) {
    $addSuccess = Invoke-Step -StepName "将所有变更添加到暂存区" -Action { git add . }
    if ($addSuccess) {
        # 检查暂存区是否真的有东西，防止 "nothing to commit" 错误
        $changesToCommit = git diff --staged --quiet;
        if ($LASTEXITCODE -ne 0) {
            Invoke-Step -StepName "提交变更到本地仓库" -Action { git commit -m $commitMessage } `
                        -SuccessAction { Write-Host "    ${Color.Info}↳ 提交信息: $commitMessage ${Color.Reset}" }
        } else {
            Write-Host "  ${Color.Success}✓ 无可提交的内容，跳过Commit步骤。 ✅ ${Color.Reset}"
        }
    }
} else {
    Write-Host "  ${Color.Info}○ 无文件变更，跳过 Add 和 Commit 步骤。${Color.Reset}"
}

# 无论有无commit，都执行一次强制推送，以确保触发远程的CI/CD流程或同步分支状态
Invoke-Step -StepName "强制推送至远程仓库" -Action { git push --force }

# --- 最终总结 ---
Write-Host
Write-Host "${Color.Info}======================[ 执行摘要 ]======================${Color.Reset}"
if ($Global:ErrorCount -gt 0) {
    Write-Host "  ${Color.Error}任务完成，但遇到了 $($Global:ErrorCount) 个错误。请检查上面的日志。 红色${Color.Reset}"
} else {
    Write-Host "  ${Color.Success}🎉 恭喜！所有任务已成功完成！${Color.Reset}"
}

if ($Global:WarningCount -gt 0) {
    Write-Host "  ${Color.Warning}本次执行产生了 $($Global:WarningCount) 个警告，请确认这些都是预期行为。 黄色${Color.Reset}"
}

Write-Host
Write-Host "  脚本执行完毕，按任意键退出..."
$null = [Console]::ReadKey($true)