function Invoke-SpinnerTask {
    <#
    .SYNOPSIS
    Executes a task with a spinner animation.

    .DESCRIPTION
    The Invoke-SpinnerTask function runs a given script block while displaying a spinner animation in the console.
    It also handles logging of the task's progress and any errors that occur.

    .PARAMETER Name
    The name of the task to be executed.

    .PARAMETER ScriptBlock
    The script block containing the code to be executed as part of the task.
    #>

    [CmdletBinding()]
    param(
        [string]$Name,
        [scriptblock]$ScriptBlock,
        [int]$Indent
    )

    process {
        Add-PSTaskLog "TASK START - $Name"
        
        $taskPosition = $Host.UI.RawUI.CursorPosition
        [Console]::CursorVisible = $false
        
        #$indent = if ($script:PSTaskJobs.Count -gt 0) { 4 } else { 0 }
        
        $jobInfo = @{
            Name = $Name
            Position = [PSCustomObject]@{
                X = $taskPosition.X + $indent
                Y = $taskPosition.Y
            }
        }
        $script:PSTaskJobs.Add($jobInfo)

        try {
            Write-TaskName -Name $Name -Indent $indent
            # Move cursor one line down so new output doesn't overwrite our task
            [Console]::SetCursorPosition(0, ($Host.UI.RawUI.CursorPosition.Y + 1))
            $job = Start-ThreadJob -Name "PSTask_$Name" -ScriptBlock ${function:Update-Spinner} -StreamingHost $Host -ArgumentList @(
                $jobInfo.Position,
                $script:Config.Spinner.Chars,
                $script:Config.Spinner.Delay,
                $script:Config.Spinner.Color
            )
            
            $output = . $ScriptBlock *>&1
            $output | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) {
                    $fullErrorMessage = Format-ErrorForLog $_
                    Add-PSTaskLog $fullErrorMessage -Level "ERROR"
                }
                else {
                    Add-PSTaskLog $_.ToString()
                }
            }
            
            $status = "Success"
        }
        catch {
            $status = "Failure"
            $fullErrorMessage = Format-ErrorForLog $_
            Add-PSTaskLog $fullErrorMessage -Level "ERROR"
        }
        finally {
            Stop-Job $job
            Remove-Job $job
            Write-FinalStatus -Name $Name -Status $status -Indent $indent
            [Console]::CursorVisible = $true

            $updatedJobs = [System.Collections.Concurrent.ConcurrentBag[hashtable]]::new()
            foreach ($item in $script:PSTaskJobs) {
                if ($item.Name -ne $Name) {
                    $updatedJobs.Add($item)
                }
            }
            $script:PSTaskJobs = $updatedJobs

            Add-PSTaskLog "TASK END - $Name - $status"
        }
    }
}