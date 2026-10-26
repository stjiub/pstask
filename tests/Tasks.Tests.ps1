BeforeAll {
    . $PSScriptRoot/TestHelper.ps1
    Import-PSTaskForTest
}

Describe 'New-PSTask' {
    BeforeEach { Reset-PSTaskState }

    Context 'Text mode' {
        It 'prints the task name, output and an OK status' {
            $out = New-PSTask -Name 'Say hello' -Mode Text -ScriptBlock { 'hello' } 6>&1 | Out-String
            $out | Should -Match '- Say hello'
            $out | Should -Match 'hello'
            $out | Should -Match '\[OK\] Say hello \(\d+\.\ds\)'
        }

        It 'reports a warning for non-terminating errors without throwing' {
            $out = New-PSTask -Name 'Noisy' -Mode Text -ScriptBlock { Write-Error 'minor' } 6>&1 2>&1 | Out-String
            $out | Should -Match '\[!\] Noisy'
            $out | Should -Match 'minor'
        }

        It 'reports a failure and swallows the exception by default' {
            { New-PSTask -Name 'Broken' -Mode Text -ScriptBlock { throw 'boom' } 6>&1 | Out-Null } | Should -Not -Throw
            $out = New-PSTask -Name 'Broken' -Mode Text -ScriptBlock { throw 'boom' } 6>&1 | Out-String
            $out | Should -Match '\[X\] Broken'
            $out | Should -Match 'boom'
        }

        It 'rethrows with -StopOnFailure' {
            { New-PSTask -Name 'Broken' -Mode Text -StopOnFailure -ScriptBlock { throw 'boom' } 6>&1 | Out-Null } | Should -Throw '*boom*'
        }
    }

    Context 'Normal mode' {
        It 'passes script block output through to the pipeline' {
            $result = New-PSTask -Name 'Value' -Mode Normal -ScriptBlock { 42 }
            $result | Should -Be 42
        }

        It 'rethrows terminating errors' {
            { New-PSTask -Name 'Broken' -Mode Normal -ScriptBlock { throw 'boom' } } | Should -Throw '*boom*'
        }
    }

    Context 'Silent mode' {
        It 'produces no host output' {
            $out = New-PSTask -Name 'Quiet' -Mode Silent -ScriptBlock { 'secret output' } 6>&1
            $out | Should -BeNullOrEmpty
        }

        It 'rethrows terminating errors' {
            { New-PSTask -Name 'Broken' -Mode Silent -ScriptBlock { throw 'boom' } } | Should -Throw '*boom*'
        }
    }

    Context 'Spinner mode' {
        It 'falls back to Text mode when output is redirected' -Skip:(-not [Console]::IsOutputRedirected) {
            $out = New-PSTask -Name 'Spin' -Mode Spinner -ScriptBlock { 'x' } 6>&1 | Out-String
            $out | Should -Match '\[OK\] Spin'
        }
    }

    Context 'Visibility' {
        It 'runs tasks below the visibility threshold silently' {
            Set-PSTaskVisibilityLevel -Level Important
            $out = New-PSTask -Name 'Hidden' -Mode Text -VisibilityLevel Normal -ScriptBlock { 'x' } 6>&1
            $out | Should -BeNullOrEmpty
        }

        It 'shows tasks at or above the visibility threshold' {
            Set-PSTaskVisibilityLevel -Level Important
            $out = New-PSTask -Name 'Shown' -Mode Text -VisibilityLevel Critical -ScriptBlock { 'x' } 6>&1 | Out-String
            $out | Should -Match 'Shown'
        }

        It 'still executes hidden tasks' {
            Set-PSTaskVisibilityLevel -Level Critical
            $script:ran = $false
            New-PSTask -Name 'Hidden' -Mode Text -ScriptBlock { $script:ran = $true } 6>&1 | Out-Null
            $script:ran | Should -BeTrue
        }
    }

    Context 'Debug mode' {
        It 'forces Normal mode so output reaches the pipeline' {
            Set-PSTaskDebug -Enabled
            $result = New-PSTask -Name 'Dbg' -Mode Silent -ScriptBlock { 'visible' }
            $result | Should -Be 'visible'
        }

        It 'restores the configured mode when disabled' {
            Set-PSTaskDebug -Enabled
            Set-PSTaskDebug -Disabled
            $result = New-PSTask -Name 'Dbg' -Mode Silent -ScriptBlock { 'hidden' }
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Nesting and StopOnFailure' {
        It 'runs child tasks inside a parent task' {
            $script:order = @()
            New-PSTask -Name 'Parent' -Mode Text -ScriptBlock {
                New-PSTask -Name 'Child 1' -Mode Text -ScriptBlock { $script:order += 'c1' }
                New-PSTask -Name 'Child 2' -Mode Text -ScriptBlock { $script:order += 'c2' }
            } 6>&1 | Out-Null
            $script:order | Should -Be 'c1', 'c2'
        }

        It 'leaves the nesting level balanced after a failure' {
            New-PSTask -Name 'Broken' -Mode Text -ScriptBlock { throw 'x' } 6>&1 | Out-Null
            InModuleScope PSTask { $script:PSTaskNestingLevel } | Should -Be 0
        }

        It 'skips later children after a failing child when the parent uses -StopOnFailure' {
            $script:order = @()
            {
                New-PSTask -Name 'Parent' -Mode Text -StopOnFailure -ScriptBlock {
                    New-PSTask -Name 'Bad' -Mode Text -ScriptBlock { throw 'x' }
                    New-PSTask -Name 'Never' -Mode Text -ScriptBlock { $script:order += 'ran' }
                } 6>&1 | Out-Null
            } | Should -Throw
            $script:order | Should -BeNullOrEmpty
        }

        It 'continues with later children without -StopOnFailure' {
            $script:order = @()
            New-PSTask -Name 'Parent' -Mode Text -ScriptBlock {
                New-PSTask -Name 'Bad' -Mode Text -ScriptBlock { throw 'x' }
                New-PSTask -Name 'Next' -Mode Text -ScriptBlock { $script:order += 'ran' }
            } 6>&1 | Out-Null
            $script:order | Should -Be 'ran'
        }

        It 'does not leak StopOnFailure to sibling tasks' {
            New-PSTask -Name 'Strict' -Mode Text -StopOnFailure -ScriptBlock { 'ok' } 6>&1 | Out-Null
            InModuleScope PSTask { $script:PSTaskStopOnFailure } | Should -BeFalse
        }
    }

    Context 'Parameter validation' {
        It 'rejects unknown modes' {
            { New-PSTask -Name 'x' -Mode Bogus -ScriptBlock { } } | Should -Throw
        }

        It 'requires a name' {
            { New-PSTask -ScriptBlock { } -Name $null } | Should -Throw
        }
    }
}

Describe 'Session settings' {
    BeforeEach { Reset-PSTaskState }

    It 'Set-PSTaskMode changes the default mode' {
        Set-PSTaskMode -Mode Silent
        InModuleScope PSTask { $script:PSTaskMode } | Should -Be 'Silent'
    }

    It 'Set-PSTaskMode rejects unknown modes' {
        { Set-PSTaskMode -Mode Bogus } | Should -Throw
    }

    It 'Set-PSTaskVisibilityLevel changes the threshold' {
        Set-PSTaskVisibilityLevel -Level Critical
        InModuleScope PSTask { [string]$script:PSTaskVisibilityLevel } | Should -Be 'Critical'
    }

    It 'Set-PSTaskDebug toggles debug mode' {
        Set-PSTaskDebug -Enabled
        InModuleScope PSTask { $script:PSTaskDebugMode } | Should -BeTrue
        Set-PSTaskDebug -Disabled
        InModuleScope PSTask { $script:PSTaskDebugMode } | Should -BeFalse
    }
}
