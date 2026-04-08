function Invoke-SilentTask {
    <#
    .SYNOPSIS
    Executes a task silently.

    .DESCRIPTION
    The Invoke-SilentTask function runs a given script block without producing any console output.
    It still handles logging of the task's progress and any errors that occur.

    .PARAMETER Name
    The name of the task to be executed.

    .PARAMETER ScriptBlock
    The script block containing the code to be executed as part of the task.
    #>

    [CmdletBinding()]
    param(
        [string]$Name,
        [scriptblock]$ScriptBlock
    )

    process {
        $taskTimer = [System.Diagnostics.Stopwatch]::StartNew()
        Write-PSTaskLog "TASK START - $Name"
        try {
            $output = . $ScriptBlock *>&1
            $output | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) {
                    $fullErrorMessage = Format-ErrorForLog $_
                    Write-PSTaskLog $fullErrorMessage -Level "ERROR"
                } else {
                    Write-PSTaskLog $_.ToString()
                }
            }
            $taskTimer.Stop()
            $durationText = "{0:N1}s" -f $taskTimer.Elapsed.TotalSeconds
            Write-PSTaskLog "TASK END - $Name - Success ($durationText)"
        }
        catch {
            $taskTimer.Stop()
            $durationText = "{0:N1}s" -f $taskTimer.Elapsed.TotalSeconds
            $fullErrorMessage = Format-ErrorForLog $_
            Write-PSTaskLog $fullErrorMessage -Level "ERROR"
            Write-PSTaskLog "TASK END - $Name - Failure ($durationText)"
            throw
        }
    }
}