<#
.SYNOPSIS
Shows PSTask in action: nested tasks, a warning, a failure, -StopOnFailure and the task tree.

.DESCRIPTION
Nothing here touches your system; every task just sleeps or writes output. Run it in an
interactive console to see the animated spinner. The run is logged to a file in $env:TEMP and shown as a tree at the end.

.EXAMPLE
./examples/Demo.ps1
#>
[CmdletBinding()]
param()

Import-Module (Join-Path $PSScriptRoot '../PSTask/PSTask.psd1') -Force

Start-PSTaskLogging -LogName 'Demo' -LogPath $env:TEMP

New-PSTask -Name 'Provision workstation' -ScriptBlock {

    New-PSTask -Name 'Prepare system' -ScriptBlock {
        New-PSTask -Name 'Check disk space' -ScriptBlock { Start-Sleep -Milliseconds 900 }
        New-PSTask -Name 'Create local account' -ScriptBlock {
            Start-Sleep -Milliseconds 1400
            'Created account svc-demo'
        }
    }

    New-PSTask -Name 'Install software' -ScriptBlock {
        New-PSTask -Name 'Install 7-Zip' -ScriptBlock { Start-Sleep -Milliseconds 1200 }

        # A non-terminating error ends the task with a warning
        New-PSTask -Name 'Install editor' -ScriptBlock {
            Start-Sleep -Milliseconds 1200
            Write-Error 'Optional extension pack skipped'
        }

        # A terminating error fails the task, and the script carries on
        New-PSTask -Name 'Install legacy agent' -ScriptBlock {
            Start-Sleep -Milliseconds 1200
            throw 'Installer returned exit code 1603'
        }
    }

    New-PSTask -Name 'Apply settings' -ScriptBlock {
        New-PSTask -Name 'Set power plan' -ScriptBlock { Start-Sleep -Milliseconds 800 }
        New-PSTask -Name 'Enable firewall' -ScriptBlock { Start-Sleep -Milliseconds 900 }
    }
}

# With -StopOnFailure a failed child stops its parent, so later children never run
try {
    New-PSTask -Name 'Deploy application' -StopOnFailure -ScriptBlock {
        New-PSTask -Name 'Build package' -ScriptBlock { Start-Sleep -Milliseconds 1000 }
        New-PSTask -Name 'Run smoke tests' -ScriptBlock {
            Start-Sleep -Milliseconds 1000
            throw 'Smoke test failed: /health returned 500'
        }
        New-PSTask -Name 'Publish package' -ScriptBlock { Start-Sleep -Milliseconds 800 }
    }
}
catch {
    Write-Host "Deployment stopped: $($_.Exception.Message)" -ForegroundColor Yellow
}

Stop-PSTaskLogging

Write-Host ''
Show-PSTaskTree
