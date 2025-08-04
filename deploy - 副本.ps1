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
}function Resolve-GitError {
    param(
        [Parameter(Mandatory=$true)]
        $jobOutput
    )
    $jobOutput = $jobOutput | Out-String
    if ($jobOutput -match "not a git repository") {
        Write-Host (" " * 4) "--当前目录不是一个Git仓库，请检查是否在博客目录下运行！" @ColorError
    } elseif ($jobOutput -match "No url found for submodule path") {
        Write-Host (" " * 4) "--在.gitmodules文件中找不到子模块的URL，请检查配置！" @ColorError
    } elseif ($jobOutput -match "repository .* not found") {
        Write-Host (" " * 4) "--找不到远程仓库，请检查URL或权限！" @ColorError
    } elseif ($jobOutput -match "branch .* not found") {
        Write-Host (" " * 4) "--主题或分支不存在！" @ColorError
    } elseif ($jobOutput -match "could not read|Connection was reset|Empty reply from server|SSL_ERROR_SYSCALL|The remote end hung up unexpectedly") {
        Write-Host (" " * 4) "--网络连接错误，无法连接到远程仓库。请检查网络、VPN或代理配置！" @ColorError
    } elseif ($jobOutput -match "fatal: Unable to fetch|fatal: Unable to fetch in submodule") {
        Write-Host (" " * 4) "--获取远程数据失败，请检查网络连接！" @ColorError
    } elseif ($jobOutput -match "pathspec .* did not match any files") {
        Write-Host (" " * 4) "--指定的文件或路径不存在，请检查`git add`命令！" @ColorError
    } elseif ($jobOutput -match "A branch named .* already exists") {
        Write-Host (" " * 4) "--本地分支已存在！" @ColorError
    } elseif ($jobOutput -match "You are not currently on a branch") {
        Write-Host (" " * 4) "--当前没有在任何分支上，请先切换到分支！" @ColorError
    } elseif ($jobOutput -match "could not lock config file") {
        Write-Host (" " * 4) "--无法锁定配置文件，可能是权限问题！" @ColorError
    } elseif ($jobOutput -match "You have not told me your name and email") {
        Write-Host (" " * 4) "--你还没有配置Git的用户名和邮箱！" @ColorError
    } elseif ($jobOutput -match "local changes .* would be overwritten") {
        Write-Host (" " * 4) "--有本地修改会覆盖远程内容，请先提交或暂存你的修改！" @ColorError
    } elseif ($jobOutput -match "Failed to merge") {
        Write-Host (" " * 4) "--合并失败，可能存在冲突！" @ColorError
    } elseif ($jobOutput -match "Updates were rejected because the tip .* is behind its remote counterpart") {
        Write-Host (" " * 4) "--推送被拒绝，因为你的本地版本落后于远程版本，请先`git pull`！" @ColorError
    } elseif ($jobOutput -match "error: failed to push some refs to") {
        Write-Host (" " * 4) "--推送失败，请检查远程仓库状态！" @ColorError
    } elseif ($jobOutput -match "Permission denied|Authentication failed") {
        Write-Host (" " * 4) "--权限不足，请检查账户或密钥配置！" @ColorError
    } elseif ($jobOutput -match "index file is corrupte") {
        Write-Host (" " * 4) "--Git索引文件已损坏，请尝试重建！" @ColorError
    } elseif ($jobOutput -match "pack has bad object") {
        Write-Host (" " * 4) "--数据包中的对象损坏了！" @ColorError
    } elseif ($jobOutput -match "HTTP 413|Request Entity Too Large") {
        Write-Host (" " * 4) "--HTTP请求体太大，可能是文件过大或`gitignore`未生效！" @ColorError
    } elseif ($jobOutput -match "cannot lock ref") {
        Write-Host (" " * 4) "--无法锁定引用，可能是其他Git操作正在进行或本地文件锁损坏！" @ColorError
    } elseif ($jobOutput -match "You are not in a git command") {
        Write-Host (" " * 4) "--你当前不在Git命令中，请检查Git是否正确安装！" @ColorError
    } else {
        # 如果没有匹配到任何已知的错误，就直接输出原始错误信息
        Write-Host (" " * 4) "--$jobOutput" @ColorError
    }
}
# 定义输出颜色
$ColorSuccess = @{ForegroundColor = 'Green'}
$ColorWarning = @{ForegroundColor = 'DarkYellow'}
$ColorError = @{ForegroundColor = 'Red'}
$ColorDefault = @{ForegroundColor = 'White'}

Write-Host  (" " * 4) "114514" @ColorDefault
# 开始记录输出
& {
    Write-Host  (" " * 4) "--提交信息: $commitMessage" @ColorDefault
    Write-Host  (" " * 4) "--将所有修改都添加到暂存区中..." @ColorDefault
    Write-Host "----------------------------------------" @ColorDefault
    Clear-LastLine 2
    Write-Host  (" " * 4) "--所有修改已经添加到暂存区中" @ColorSuccess
    Write-Host  (" " * 4) "--将所有修改都添加..." @ColorDefault
    Write-Host  (" " * 4) "--将所有修改都." @ColorDefault
    Write-Host  (" " * 4) "--将所有修改..." @ColorDefault
    Write-Host  (" " * 4) "--将改都添加..." @ColorDefault
    Clear-LastLine 1
    Write-Host  (" " * 4) "--将所有修改都." @ColorDefault
} 6>&1 | Tee-Object -Variable tempOutput
Start-Sleep -Seconds 2
# 循环遍历 Tee-Object 捕获到的内容，并追加到数组
foreach ($line in $tempOutput) {
    if ($line.MessageData.Message.Trim().Length -eq 0) {
            $lineSu--
    } else{
            $lineSu++
    }
}
Clear-LastLine $lineSu
Write-Host  (" " * 4) "1145141919810" @ColorDefault
foreach ($line in $tempOutput) {
    if ($line.MessageData.Message.Trim().Length -eq 0) {
            # 如果是空行，就输出你想要的内容
            Clear-LastLine 1
        }
    else {
            # 如果不是空行，就正常输出
        Write-Host $line.MessageData.Message -ForegroundColor $line.MessageData.ForegroundColor -BackgroundColor $line.MessageData.BackgroundColor
        }
}