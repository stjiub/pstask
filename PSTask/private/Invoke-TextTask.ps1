function Invoke-TextTask {
    <#
    .SYNOPSIS
    Executes a task with text output.

    .DESCRIPTION
    The Invoke-TextTask function runs a given script block and outputs the results as text to the console.
    It also handles logging of the task's progress and any errors that occur.

    .PARAMETER Name
    The name of the task to be executed.

    .PARAMETER ScriptBlock
    The script block containing the code to be executed as part of the task.

    .PARAMETER StopOnFailure
    When specified, re-throws the error after displaying failure status to cascade the failure to parent tasks.
    #>
    
    [CmdletBinding()]
    param(
        [string]$Name,
        [scriptblock]$ScriptBlock,
        [switch]$StopOnFailure
    )

    process {
        $taskTimer = [System.Diagnostics.Stopwatch]::StartNew()
        Write-PSTaskLog "TASK START - $Name"

        Write-Host "- $Name" -ForegroundColor $script:Config.DefaultColor
        try {
            $output = . $ScriptBlock *>&1
            $hasErrors = $false
            $output | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) {
                    $hasErrors = $true
                    $fullErrorMessage = Format-ErrorForLog $_
                    Write-PSTaskLog $fullErrorMessage -Level "ERROR"
                    Write-Host $_.Exception.Message -ForegroundColor $script:Config.StatusColors.Failure
                } else {
                    Write-PSTaskLog $_.ToString()
                    Write-Host $_
                }
            }
            $taskTimer.Stop()
            $durationText = "{0:N1}s" -f $taskTimer.Elapsed.TotalSeconds
            if ($hasErrors) {
                Write-Host "[!] $Name ($durationText)" -ForegroundColor $script:Config.StatusColors.Warning
                Write-PSTaskLog "TASK END - $Name - Warning ($durationText)"
            } else {
                Write-Host "[OK] $Name ($durationText)" -ForegroundColor $script:Config.StatusColors.Success
                Write-PSTaskLog "TASK END - $Name - Success ($durationText)"
            }
        }
        catch {
            $taskTimer.Stop()
            $durationText = "{0:N1}s" -f $taskTimer.Elapsed.TotalSeconds
            $fullErrorMessage = Format-ErrorForLog $_
            Write-Host "[X] $Name ($durationText)" -ForegroundColor $script:Config.StatusColors.Failure
            Write-Host $_.Exception.Message -ForegroundColor $script:Config.StatusColors.Failure
            Write-PSTaskLog $fullErrorMessage -Level "ERROR"
            Write-PSTaskLog "TASK END - $Name - Failure ($durationText)"

            if ($StopOnFailure) {
                throw
            }
        }
    }
}