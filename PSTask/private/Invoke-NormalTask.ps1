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
        Add-PSTaskLog "TASK START - $Name"
        try {
            # Execute the script block and capture output
            $output = . $ScriptBlock *>&1
            
            # Process each output item
            $output | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) {
                    $fullErrorMessage = Format-ErrorForLog $_
                    Add-PSTaskLog $fullErrorMessage -Level "ERROR"
                    # Write error to error stream
                    $_ | Write-Error
                } else {
                    Add-PSTaskLog $_.ToString()
                    # Write output to output stream
                    $_
                }
            }
            
            Add-PSTaskLog "TASK END - $Name - Success"
        }
        catch {
            $fullErrorMessage = Format-ErrorForLog $_
            Add-PSTaskLog $fullErrorMessage -Level "ERROR"
            Add-PSTaskLog "TASK END - $Name - Failure"
            throw  # Re-throw the error to maintain normal PowerShell error handling
        }
    }
}