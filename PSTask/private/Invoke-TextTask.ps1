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
    #>
    
    [CmdletBinding()]
    param(
        [string]$Name,
        [scriptblock]$ScriptBlock
    )

    process {
        Write-PSTaskLog "TASK START - $Name"

        Write-Host "- $Name" -ForegroundColor $script:Config.DefaultColor
        try {
            $output = . $ScriptBlock *>&1
            $output | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) {
                    $fullErrorMessage = Format-ErrorForLog $_
                    Write-PSTaskLog $fullErrorMessage -Level "ERROR"
                    Write-Host $_.Exception.Message -ForegroundColor $script:Config.StatusColors.Failure
                } else {
                    Write-PSTaskLog $_.ToString()
                    Write-Host $_
                }
            }
            Write-Host "[OK] $Name" -ForegroundColor $script:Config.StatusColors.Success
            Write-PSTaskLog "TASK END - $Name - Success"
        }
        catch {
            $fullErrorMessage = Format-ErrorForLog $_
            Write-Host "X $Name" -ForegroundColor $script:Config.StatusColors.Failure
            Write-Host $_.Exception.Message -ForegroundColor $script:Config.StatusColors.Failure
            Write-PSTaskLog $fullErrorMessage -Level "ERROR"
            Write-PSTaskLog "TASK END - $Name - Failure"
        }
    }
}