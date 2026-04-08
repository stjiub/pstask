function Invoke-NormalTask {
    <#
    .SYNOPSIS
    Executes a task with normal PowerShell output behavior.

    .DESCRIPTION
    The Invoke-NormalTask function runs a given script block and allows output to flow normally to the console,
    maintaining standard PowerShell output behavior while still providing task tracking and logging capabilities.

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
            # Execute the script block and capture output
            $output = . $ScriptBlock *>&1
            
            # Process each output item
            $hasErrors = $false
            $output | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) {
                    $hasErrors = $true
                    $fullErrorMessage = Format-ErrorForLog $_
                    Write-PSTaskLog $fullErrorMessage -Level "ERROR"
                    # Write error to error stream
                    $_ | Write-Error
                } else {
                    Write-PSTaskLog $_.ToString()
                    # Write output to output stream
                    $_
                }
            }

            $taskTimer.Stop()
            $durationText = "{0:N1}s" -f $taskTimer.Elapsed.TotalSeconds
            $status = if ($hasErrors) { "Warning" } else { "Success" }
            Write-PSTaskLog "TASK END - $Name - $status ($durationText)"
        }
        catch {
            $taskTimer.Stop()
            $durationText = "{0:N1}s" -f $taskTimer.Elapsed.TotalSeconds
            $fullErrorMessage = Format-ErrorForLog $_
            Write-PSTaskLog $fullErrorMessage -Level "ERROR"
            Write-PSTaskLog "TASK END - $Name - Failure ($durationText)"
            throw  # Re-throw the error to maintain normal PowerShell error handling
        }
    }
}