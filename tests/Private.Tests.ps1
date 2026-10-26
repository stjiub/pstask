BeforeAll {
    . $PSScriptRoot/TestHelper.ps1
    Import-PSTaskForTest
}

Describe 'Format-ErrorForLog' {
    It 'includes exception type, message and stack trace header' {
        InModuleScope PSTask {
            try { throw 'bad news' } catch { $record = $_ }
            $text = Format-ErrorForLog $record
            $text | Should -Match 'Exception Type: System\.Management\.Automation\.RuntimeException'
            $text | Should -Match 'Exception Message: bad news'
            $text | Should -Match 'Stack Trace:'
        }
    }
}

Describe 'Get-PSTaskLogFileName' {
    It 'appends the log name to a timestamp' {
        InModuleScope PSTask {
            Get-PSTaskLogFileName -LogName 'Thing' | Should -Match '^\d{4}-[A-Za-z]{3}-\d{2}_\d{2}-\d{2}-\d{2}-Thing\.log$'
        }
    }

    It 'works without a log name' {
        InModuleScope PSTask {
            Get-PSTaskLogFileName | Should -Match '^\d{4}-[A-Za-z]{3}-\d{2}_\d{2}-\d{2}-\d{2}\.log$'
        }
    }
}

Describe 'Task runners' -ForEach @(
    @{ Runner = 'Invoke-SilentTask' }
    @{ Runner = 'Invoke-NormalTask' }
    @{ Runner = 'Invoke-TextTask' }
) {
    BeforeEach { Reset-PSTaskState }

    It '<Runner> logs a successful task' {
        $log = Join-Path $TestDrive "$Runner.log"
        Start-PSTaskLogging -LogName 'R' -LogPathOverride $log
        & (Get-Module PSTask) { param($r) & $r -Name 'T' -ScriptBlock { 'ok' } } $Runner 6>&1 | Out-Null
        Stop-PSTaskLogging
        Get-Content $log -Raw | Should -Match 'TASK END - T - Success'
    }

    It '<Runner> logs a failed task and rethrows' {
        $log = Join-Path $TestDrive "$Runner-fail.log"
        Start-PSTaskLogging -LogName 'R' -LogPathOverride $log
        $threw = $false
        try { & (Get-Module PSTask) { param($r) & $r -Name 'T' -ScriptBlock { throw 'x' } -ErrorAction Stop } $Runner 6>&1 | Out-Null }
        catch { $threw = $true }
        Stop-PSTaskLogging
        Get-Content $log -Raw | Should -Match 'TASK END - T - Failure'
    }
}
