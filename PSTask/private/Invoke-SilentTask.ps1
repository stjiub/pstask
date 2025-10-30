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
            Write-PSTaskLog "TASK END - $Name - Success"
        }
        catch {
            $fullErrorMessage = Format-ErrorForLog $_
            Write-PSTaskLog $fullErrorMessage -Level "ERROR"
            Write-PSTaskLog "TASK END - $Name - Failure"
            throw
        }
    }
}