BeforeAll {
    . $PSScriptRoot/TestHelper.ps1
    Import-PSTaskForTest
}

Describe 'Start-PSTaskLogging / Stop-PSTaskLogging' {
    BeforeEach {
        Reset-PSTaskState
        $script:dir = (New-Item -ItemType Directory -Path (Join-Path $TestDrive ([guid]::NewGuid()))).FullName
    }

    It 'creates a timestamped log file in LogPath with a header' {
        Start-PSTaskLogging -LogName 'Demo' -LogPath $dir
        $file = Get-ChildItem $dir -Filter '*-Demo.log'
        Stop-PSTaskLogging
        $file | Should -HaveCount 1
        $file.Name | Should -Match '^\d{4}-[A-Za-z]{3}-\d{2}_\d{2}-\d{2}-\d{2}-Demo\.log$'
        $content = Get-Content $file.FullName -Raw
        $content | Should -Match 'PSTask Log'
        $content | Should -Match 'Script: Demo'
        $content | Should -Match 'PSVersion: '
    }

    It 'includes custom fields in the header' {
        Start-PSTaskLogging -LogName 'Demo' -LogPath $dir -CustomFields @{ Environment = 'Prod' }
        $path = InModuleScope PSTask { $script:PSTaskLoggingState.LogPath }
        Stop-PSTaskLogging
        Get-Content $path -Raw | Should -Match 'Environment: Prod'
    }

    It 'writes to the exact file given by -LogPathOverride' {
        $target = Join-Path $TestDrive 'exact.log'
        Start-PSTaskLogging -LogName 'Demo' -LogPathOverride $target
        Stop-PSTaskLogging
        $target | Should -Exist
    }

    It 'rejects -LogPath together with -LogPathOverride' {
        { Start-PSTaskLogging -LogName 'Demo' -LogPath $dir -LogPathOverride (Join-Path $TestDrive 'x.log') } | Should -Throw '*Cannot specify both*'
    }

    It 'ref-counts nested starts and only stops at zero' {
        Start-PSTaskLogging -LogName 'Demo' -LogPath $dir
        Start-PSTaskLogging -LogName 'Demo' -LogPath $dir
        Stop-PSTaskLogging
        InModuleScope PSTask { $script:PSTaskLoggingState.IsLogging } | Should -BeTrue
        Stop-PSTaskLogging
        InModuleScope PSTask { $script:PSTaskLoggingState.IsLogging } | Should -BeFalse
    }

    It 'writes a footer and remembers the last log path on stop' {
        Start-PSTaskLogging -LogName 'Demo' -LogPath $dir
        $path = InModuleScope PSTask { $script:PSTaskLoggingState.LogPath }
        Stop-PSTaskLogging
        Get-Content $path -Raw | Should -Match 'Log Ended:'
        InModuleScope PSTask { $script:PSTaskLoggingState.LastLogPath } | Should -Be $path
        InModuleScope PSTask { $script:PSTaskLoggingState.LogPath } | Should -BeNullOrEmpty
    }

    It 'Stop-PSTaskLogging is a no-op when not logging' {
        { Stop-PSTaskLogging } | Should -Not -Throw
    }
}

Describe 'Write-PSTaskLog' {
    BeforeEach { Reset-PSTaskState }

    It 'appends leveled, timestamped entries' {
        $target = Join-Path $TestDrive 'w.log'
        Start-PSTaskLogging -LogName 'Demo' -LogPathOverride $target
        Write-PSTaskLog 'first'
        Write-PSTaskLog 'second' -Level WARNING
        Stop-PSTaskLogging
        $lines = Get-Content $target
        @($lines -match '^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[INFO\] first$') | Should -HaveCount 1
        @($lines -match '\[WARNING\] second') | Should -HaveCount 1
    }

    It 'does nothing when logging is inactive' {
        { Write-PSTaskLog 'nobody listening' } | Should -Not -Throw
    }

    It 'rejects unknown levels' {
        { Write-PSTaskLog 'x' -Level DEBUG } | Should -Throw
    }
}

Describe 'New-PSTask logging' {
    BeforeEach {
        Reset-PSTaskState
        $script:dir = (New-Item -ItemType Directory -Path (Join-Path $TestDrive ([guid]::NewGuid()))).FullName
    }

    It 'logs task start, output and success with duration' {
        New-PSTask -Name 'Work' -Mode Text -LogName 'Demo' -LogPath $dir -ScriptBlock { 'did a thing' } 6>&1 | Out-Null
        $path = InModuleScope PSTask { $script:PSTaskLoggingState.LastLogPath }
        $content = Get-Content $path -Raw
        $content | Should -Match 'TASK START - Work'
        $content | Should -Match 'did a thing'
        $content | Should -Match 'TASK END - Work - Success \(\d+\.\ds\)'
    }

    It 'logs failures at ERROR level with exception details' {
        { New-PSTask -Name 'Bad' -Mode Silent -LogName 'Demo' -LogPath $dir -ScriptBlock { throw 'kaboom' } } | Should -Throw
        $path = InModuleScope PSTask { $script:PSTaskLoggingState.LastLogPath }
        $content = Get-Content $path -Raw
        $content | Should -Match '\[ERROR\] Exception Type:'
        $content | Should -Match 'kaboom'
        $content | Should -Match 'TASK END - Bad - Failure'
    }

    It 'logs a warning status for non-terminating errors' {
        New-PSTask -Name 'Meh' -Mode Text -LogName 'Demo' -LogPath $dir -ScriptBlock { Write-Error 'minor' } 6>&1 2>&1 | Out-Null
        $path = InModuleScope PSTask { $script:PSTaskLoggingState.LastLogPath }
        Get-Content $path -Raw | Should -Match 'TASK END - Meh - Warning'
    }

    It 'shares one log across nested tasks and stops it once' {
        New-PSTask -Name 'Outer' -Mode Text -LogName 'Demo' -LogPath $dir -ScriptBlock {
            New-PSTask -Name 'Inner' -Mode Text -ScriptBlock { 'x' }
        } 6>&1 | Out-Null
        @(Get-ChildItem $dir -Filter '*-Demo.log') | Should -HaveCount 1
        InModuleScope PSTask { $script:PSTaskLoggingState.IsLogging } | Should -BeFalse
        $content = Get-Content (Get-ChildItem $dir -Filter '*-Demo.log').FullName -Raw
        ([regex]::Matches($content, 'Log Ended:')).Count | Should -Be 1
    }
}

Describe 'Show-PSTaskLog' {
    BeforeAll {
        $script:sample = Join-Path $TestDrive 'sample.log'
        @(
            '**********************'
            'PSTask Log'
            '[2026-01-01 10:00:00] [INFO] TASK START - Alpha'
            '[2026-01-01 10:00:01] [INFO] hello'
            '[2026-01-01 10:00:01] [WARNING] careful'
            '[2026-01-01 10:00:02] [ERROR] bad thing'
            '[2026-01-01 10:00:02] [INFO] TASK END - Alpha - Failure (2.0s)'
        ) | Set-Content $sample
    }

    BeforeEach { Reset-PSTaskState }

    It 'warns when no log is available' {
        Show-PSTaskLog 3>&1 | Should -Match 'No log file available'
    }

    It 'warns when the file does not exist' {
        Show-PSTaskLog -LogPath (Join-Path $TestDrive 'missing.log') 3>&1 | Should -Match 'not found'
    }

    It 'prints every line by default' {
        (Show-PSTaskLog -LogPath $sample 6>&1 | Out-String) | Should -Match 'TASK START - Alpha[\s\S]*TASK END'
    }

    It 'limits output with -Tail' {
        @(Show-PSTaskLog -LogPath $sample -Tail 2 6>&1) | Should -HaveCount 2
    }

    It 'filters structured entries by minimum level' {
        $out = Show-PSTaskLog -LogPath $sample -Level ERROR 6>&1 | Out-String
        $out | Should -Match 'bad thing'
        $out | Should -Not -Match 'hello'
        $out | Should -Not -Match 'careful'
    }

    It 'falls back to the last completed log' {
        InModuleScope PSTask -Parameters @{ p = $sample } { param($p) $script:PSTaskLoggingState.LastLogPath = $p }
        (Show-PSTaskLog 6>&1 | Out-String) | Should -Match 'hello'
    }
}

Describe 'Show-PSTaskTree' {
    BeforeEach { Reset-PSTaskState }

    It 'warns when no log is available' {
        Show-PSTaskTree 3>&1 | Should -Match 'No log file available'
    }

    It 'renders parent/child hierarchy with statuses' {
        $log = Join-Path $TestDrive 'tree.log'
        @(
            '[2026-01-01 10:00:00] [INFO] TASK START - Root'
            '[2026-01-01 10:00:00] [INFO] TASK START - Child A'
            '[2026-01-01 10:00:01] [INFO] TASK END - Child A - Success (1.0s)'
            '[2026-01-01 10:00:01] [INFO] TASK START - Child B'
            '[2026-01-01 10:00:03] [INFO] TASK END - Child B - Failure (2.0s)'
            '[2026-01-01 10:00:03] [INFO] TASK END - Root - Failure (3.0s)'
        ) | Set-Content $log
        $out = Show-PSTaskTree -LogPath $log 6>&1 | Out-String
        $out | Should -Match 'Root \[3\.0s\]'
        $out | Should -Match '(?m)^├──Child A \[1\.0s\] \[OK\]'
        $out | Should -Match '(?m)^└──Child B \[2\.0s\] \[X\]'
    }

    It 'uses the last completed log when no path is given' {
        $log = Join-Path $TestDrive 'last.log'
        @(
            '[2026-01-01 10:00:00] [INFO] TASK START - Only'
            '[2026-01-01 10:00:01] [INFO] TASK END - Only - Success (1.0s)'
        ) | Set-Content $log
        InModuleScope PSTask -Parameters @{ p = $log } { param($p) $script:PSTaskLoggingState.LastLogPath = $p }
        (Show-PSTaskTree 6>&1 | Out-String) | Should -Match 'Only \[1\.0s\]'
    }
}
