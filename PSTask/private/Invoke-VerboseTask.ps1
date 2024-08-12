function Invoke-VerboseTask {
    <#
    .SYNOPSIS
    Executes a task with verbose output.

    .DESCRIPTION
    The Invoke-VerboseTask function runs a given script block and outputs the results using Write-Verbose.
    It also handles logging of the task's progress and any errors that occur.

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
        Add-PSTaskLog "TASK START - $Name"
        Write-Verbose "Starting task: $Name"
        try {
            $output = . $ScriptBlock *>&1
            $output | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) {
                    $fullErrorMessage = Format-ErrorForLog $_
                    Add-PSTaskLog $fullErrorMessage -Level "ERROR"
                    Write-Verbose "ERROR: $($_.Exception.Message)"
                } else {
                    Add-PSTaskLog $_.ToString()
                    Write-Verbose $_
                }
            }
            Write-Verbose "Task completed successfully: $Name"
            Add-PSTaskLog "TASK END - $Name - Success"
        }
        catch {
            $fullErrorMessage = Format-ErrorForLog $_
            Write-Verbose "Task failed: $Name"
            Write-Verbose $_.Exception.Message
            Add-PSTaskLog $fullErrorMessage -Level "ERROR"
            Add-PSTaskLog "TASK END - $Name - Failure"
            throw
        }
    }
}