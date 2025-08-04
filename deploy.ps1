[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# 定义输出颜色
$CR = "`e[91m"
$CG = "`e[92m"
$CY = "`e[93m"
$CW = "`e[97m"
$RC = "`e[0m"

$IntError = 0 # 错误数量
$publicPath = ".\public"
#Gemini写的三个函数
function Resolve-GitError {
    param(
        [Parameter(Mandatory=$true)]
        $jobOutput
    )
    $jobOutput = $jobOutput | Out-String
    if ($jobOutput -match "not a git repository") {
        Write-Host (" " * 4) "${CW}----${CR}当前目录不是一个Git仓库，请检查是否在博客目录下运行！$RC"
    } elseif ($jobOutput -match "No url found for submodule path") {
        Write-Host (" " * 4) "${CW}----${CR}在.gitmodules文件中找不到子模块的URL，请检查配置！$RC"
    } elseif ($jobOutput -match "repository .* not found") {
        Write-Host (" " * 4) "${CW}----${CR}找不到远程仓库，请检查URL或权限！$RC"
    } elseif ($jobOutput -match "branch .* not found") {
        Write-Host (" " * 4) "${CW}----${CR}主题或分支不存在！$RC"
    } elseif ($jobOutput -match "could not read|Connection was reset|Empty reply from server|SSL_ERROR_SYSCALL|The remote end hung up unexpectedly") {
        Write-Host (" " * 4) "${CW}----${CR}网络连接错误，无法连接到远程仓库。请检查网络、VPN或代理配置！$RC"
    } elseif ($jobOutput -match "fatal: Unable to fetch|fatal: Unable to fetch in submodule") {
        Write-Host (" " * 4) "${CW}----${CR}获取远程数据失败，请检查网络连接！$RC"
    } elseif ($jobOutput -match "pathspec .* did not match any files") {
        Write-Host (" " * 4) "${CW}----${CR}指定的文件或路径不存在，请检查`git add`命令！$RC"
    } elseif ($jobOutput -match "A branch named .* already exists") {
        Write-Host (" " * 4) "${CW}----${CR}本地分支已存在！$RC"
    } elseif ($jobOutput -match "You are not currently on a branch") {
        Write-Host (" " * 4) "${CW}----${CR}当前没有在任何分支上，请先切换到分支！$RC"
    } elseif ($jobOutput -match "could not lock config file") {
        Write-Host (" " * 4) "${CW}----${CR}无法锁定配置文件，可能是权限问题！$RC"
    } elseif ($jobOutput -match "You have not told me your name and email") {
        Write-Host (" " * 4) "${CW}----${CR}你还没有配置Git的用户名和邮箱！$RC"
    } elseif ($jobOutput -match "local changes .* would be overwritten") {
        Write-Host (" " * 4) "${CW}----${CR}有本地修改会覆盖远程内容，请先提交或暂存你的修改！$RC"
    } elseif ($jobOutput -match "Failed to merge") {
        Write-Host (" " * 4) "${CW}----${CR}合并失败，可能存在冲突！$RC"
    } elseif ($jobOutput -match "Updates were rejected because the tip .* is behind its remote counterpart") {
        Write-Host (" " * 4) "${CW}----${CR}推送被拒绝，因为你的本地版本落后于远程版本，请先`git pull`！$RC"
    } elseif ($jobOutput -match "error: failed to push some refs to") {
        Write-Host (" " * 4) "${CW}----${CR}推送失败，请检查远程仓库状态！$RC"
    } elseif ($jobOutput -match "Permission denied|Authentication failed") {
        Write-Host (" " * 4) "${CW}----${CR}权限不足，请检查账户或密钥配置！$RC"
    } elseif ($jobOutput -match "index file is corrupte") {
        Write-Host (" " * 4) "${CW}----${CR}Git索引文件已损坏，请尝试重建！$RC"
    } elseif ($jobOutput -match "pack has bad object") {
        Write-Host (" " * 4) "${CW}----${CR}数据包中的对象损坏了！"
    } elseif ($jobOutput -match "HTTP 413|Request Entity Too Large") {
        Write-Host (" " * 4) "${CW}----${CR}HTTP请求体太大，可能是文件过大或`gitignore`未生效！$RC"
    } elseif ($jobOutput -match "cannot lock ref") {
        Write-Host (" " * 4) "${CW}----${CR}无法锁定引用，可能是其他Git操作正在进行或本地文件锁损坏！$RC"
    } elseif ($jobOutput -match "You are not in a git command") {
        Write-Host (" " * 4) "${CW}----${CR}你当前不在Git命令中，请检查Git是否正确安装！$RC"
    } else {
        # 如果没有匹配到任何已知的错误，就直接输出原始错误信息
        Write-Host (" " * 4) "${CW}----${CR}$jobOutput $RC"
    }
}
function Clear-LastLine {
    param(
        [Parameter(Mandatory = $false)]
        [int]$LinesToClear = 1 # 新增参数，默认清空1行
    )

    # 记录函数被调用时的当前光标行位置
    $initialCursorTop = [System.Console]::CursorTop

    # 获取控制台的宽度
    $lineWidth = [System.Console]::WindowWidth

    # 循环指定次数，清空每一行
    for ($i = 1; $i -le $LinesToClear; $i++) {
        # 计算要清空的行号，从当前光标位置向上数
        $targetLine = $initialCursorTop - $i

        # 如果计算出的行号小于0（即超出控制台顶部），就停止
        if ($targetLine -lt 0) {
            break
        }

        # 将光标移动到目标行的行首
        [System.Console]::SetCursorPosition(0, $targetLine)

        # 用空格覆盖整行，实现清空
        Write-Host (" " * $lineWidth) -NoNewline

        # 再次将光标移动到刚刚清空的行的行首
        # 这一步确保光标停留在被清空的行上，为下一次循环或最终定位做准备
        [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop)
    }

    # 所有行清空完毕后，将光标移动到最上面被清空的行的行首
    # 这样新的输出就会从这里开始，覆盖掉之前的内容
    [System.Console]::SetCursorPosition(0, $initialCursorTop - $LinesToClear)
}

function Get-GitStatusFormatted {
    # 执行 git status 命令并捕获所有输出
    $statusOutput = git status 2>&1

    # 按行分割输出内容
    $lines = $statusOutput.Split("`n")

    # 定义一个数组来存放格式化后的输出
    $formattedOutput = @()
    
    # 提取分支信息和状态
    $branchInfoLine = $lines | Select-String -Pattern "^On branch\s+(.*)"
    $branchStatusLine = $lines | Select-String -Pattern "Your branch is (.*)"
    
    # 判断当前分支是否是 main
    if ($branchInfoLine) {
        $branchName = $branchInfoLine.Matches.Groups[1].Value.Trim()
        if ($branchName -ne "main") {
            $formattedOutput += '警告：当前分支不是 `main`，而是 `$branchName`'
        }
    }

    # 判断分支状态是否完全同步
    if ($branchStatusLine) {
        $statusMessage = $branchStatusLine.Matches.Groups[1].Value.Trim()
        if ($statusMessage -ne "up to date with 'origin/main'.") {
            $formattedOutput += '警告：分支状态不完全同步，当前状态是 `$statusMessage`'
        }
    }

    # 遍历每一行，提取文件变更
    foreach ($line in $lines) {
        $trimmedLine = $line.Trim()

        if ($trimmedLine -match "^new file:\s+(.*)") {
            $fileName = $Matches[1].Trim()
            $formattedOutput += "新增文件：$fileName"
        } elseif ($trimmedLine -match "^modified:\s+(.*)") {
            $fileName = $Matches[1].Trim()
            $formattedOutput += "修改文件：$fileName"
        } elseif ($trimmedLine -match "^deleted:\s+(.*)") {
            $fileName = $Matches[1].Trim()
            $formattedOutput += "删除文件：$fileName"
        }
    }

    # 返回格式化后的结果
    return $formattedOutput
}
# 先更新下主题
Write-Host "${CW}----------------------------------------$RC"
Write-Host  (" " * 4) "${CW}○-正在更新主题文件...$RC"
Write-Host "${CW}----------------------------------------$RC"
$jobOutput = git submodule update --remote 2>&1
Clear-LastLine 2
if ($LASTEXITCODE -eq 0) {
    Write-Host  (" " * 4) "${CG}✔-更新主题文件成功！$RC"
}else {
    Write-Host  (" " * 4) "${CR}✘-更新主题文件失败：$RC"
    $IntError++
    Resolve-GitError $jobOutput
}
Write-Host  (" " * 4) "${CW}○-正在重置所有主题文件...$RC"
Write-Host "${CW}----------------------------------------$RC"
$jobOutput = git submodule foreach --recursive "git reset --hard && git clean -fdx" 2>&1# 删掉多余的主题文件
Clear-LastLine 2
if ($LASTEXITCODE -eq 0) {
    Write-Host  (" " * 4) "${CG}✔-重置主题文件成功！$RC"
    $themeList = ([regex]::Matches($jobOutput, "Entering 'themes/(.*?)'") | ForEach-Object { $_.Groups[1].Value }) -join "、"
    Write-Host (" " * 4) "${CW}----拥有主题：$themeList $RC"
}else {
    Write-Host  (" " * 4) "${CR}✘-重置主题文件失败：$RC"
    $IntError++
    Resolve-GitError $jobOutput
}
# 删除构建文件
if (-not (Test-Path -Path $publicPath)) {
    # 如果路径不存在
    Write-Host  (" " * 4) "${CG}✔-没有本地构建文件$RC"
} else {
    Write-Host  (" " * 4) "${CW}○-正在删除本地构建文件...$RC"
    Write-Host "${CW}----------------------------------------$RC"
    try {
        # 如果路径存在，尝试删除它
        Remove-Item -Path $publicPath -Recurse -Force -ErrorAction Stop -ProgressAction SilentlyContinue
        Clear-LastLine 2
        Write-Host  (" " * 4) "${CG}✔-删除本地构建文件成功！$RC"
    } catch {
        Clear-LastLine 2
        # 根据错误类型进行判断
        $errorMessage = $_.Exception.Message
        Write-Host (" " * 4) "${CR}✘-删除本地构建文件失败：$RC"
        if ($errorMessage -match "Access to the path") {
            Write-Host (" " * 4) "${CW}----${CR}权限不足，无法删除该文件夹。$RC"
        } elseif ($errorMessage -match "because it is being used by another process") {
            Write-Host (" " * 4) "${CW}----${CR}文件夹或文件正在被其他程序占用，请关闭相关程序后重试。$RC"
        } elseif ($errorMessage -match "Could not find a part of the path") {
            Write-Host (" " * 4) "${CW}----${CR}路径不存在，可能在删除时已被移动或删除。$RC"
        } else {
            Write-Host (" " * 4) "${CW}----${CR}未知错误：$RC"
            Write-Host (" " * 4) "${CW}----${CR}$errorMessage"
        }
    }
}

# 获取当前日期和时间，并格式化
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$commitMessage = "Update at $timestamp"
$lineSu = 1
Write-Host  (" " * 4) "${CW}○-正在同步并部署网站...$RC"
# 开始记录输出
& {
    Write-Host  (" " * 4) "${CW}----将所有修改都添加到暂存区中...$RC"
    Write-Host "${CW}----------------------------------------$RC"
    $jobOutput = git add . 2>&1 # 把所有修改都添加到暂存区
    Clear-LastLine 2
    if ($LASTEXITCODE -eq 0) {
        Write-Host  (" " * 4) "${CW}----${CG}所有修改已经添加到暂存区中$RC"
    }else {
        Write-Host  (" " * 4) "${CW}----${CR}修改未添加到暂存区中：$RC"
        $IntError++
        Resolve-GitError $jobOutput
    }
    Write-Host  (" " * 4) "${CW}--提交暂存区文件中...$RC"
    Write-Host "${CW}----------------------------------------$RC"
    $jobOutput = git commit -m $commitMessage 2>&1 # 提交暂存区文件
    Clear-LastLine 2
    if ($LASTEXITCODE -eq 0) {
        Write-Host  (" " * 4) "${CW}----${CG}已提交暂存区文件$RC"
        Write-Host  (" " * 4) "${CW}------提交信息: $commitMessage $RC"
    }else {
        Write-Host  (" " * 4) "${CW}----${CR}提交暂存区文件失败：$RC"
        $IntError++
        Resolve-GitError $jobOutput
    }
    Write-Host  (" " * 4) "${CW}----将本地重置到最新的提交中...$RC"
    Write-Host "${CW}----------------------------------------$RC"
    $jobOutput = git reset --hard HEAD 2>&1 # 同步远程仓库并 rebase，避免产生合并提交
    Clear-LastLine 2
    if ($LASTEXITCODE -eq 0) {
        Write-Host  (" " * 4) "${CW}----${CG}本地重置到最新的提交成功！$RC"
    }else {
        Write-Host  (" " * 4) "${CW}----${CR}本地重置到最新的提交失败：$RC"
        $IntError++
        Resolve-GitError $jobOutput
    }
    Write-Host  (" " * 4) "${CW}----覆盖远程仓库的分支中...$RC"
    Write-Host "${CW}----------------------------------------$RC"
    $jobOutput = git push --force 2>&1 
    Clear-LastLine 2
    if ($LASTEXITCODE -eq 0) {
        Write-Host  (" " * 4) "${CW}----${CG}覆盖远程仓库的分支成功！$RC"
    }else {
        Write-Host  (" " * 4) "${CW}----${CR}覆盖远程仓库的分支失败：$RC"
        $IntError++
        Resolve-GitError $jobOutput
    }
} 6>&1 | Tee-Object -Variable tempOutput

Start-Sleep -Seconds 3
exit 0

foreach ($line in $tempOutput) {#计算要清空的行数
    if ($line.MessageData.Message.Trim().Length -eq 0) {
            $lineSu--
    } else{
            $lineSu++
    }
}
Clear-LastLine $lineSu # 清空
Write-Host  (" " * 4) "1145141919810"
foreach ($line in $tempOutput) {# 出现输出下面的内容
    if ($line.MessageData.Message.Trim().Length -eq 0) {
            # 如果是空行，就输出你想要的内容
            Clear-LastLine 1
        }
    else {
            # 如果不是空行，就正常输出
            Write-Host $line.MessageData.Message -ForegroundColor $line.MessageData.ForegroundColor -BackgroundColor $line.MessageData.BackgroundColor
        }
}
exit 0


# 推送本地修改到远程仓库
git push


:end
exit 0
Write-Host "----------------------------------------"
Write-Host "部署完成"
Write-Host "----------------------------------------"
# 暂停
Read-Host "回车键继续..."