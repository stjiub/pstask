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

    .PARAMETER Indent
    The number of spaces to indent the task display.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [Parameter(Mandatory = $false)]
        [int]$Indent = 0
    )
    
    process {
        Add-PSTaskLog "TASK START - $Name"
        
        # Save current cursor state
        $originalCursorVisible = [Console]::CursorVisible
        [Console]::CursorVisible = $false
        
        # Get current cursor position
        $taskPosition = $Host.UI.RawUI.CursorPosition
        
        # Generate unique ID for this task
        $taskId = [Guid]::NewGuid().ToString()
        
        $jobInfo = @{
            Id = $taskId
            Name = $Name
            Position = [PSCustomObject]@{
                X = $taskPosition.X + $Indent
                Y = $taskPosition.Y
            }
            Active = $true
        }
        
        # Add to jobs collection
        $script:PSTaskJobs.Add($jobInfo)
        
        try {
            # Write initial task name
            Write-TaskName -Name $Name -Indent $Indent
            
            # Move cursor down one line for output
            $newY = $Host.UI.RawUI.CursorPosition.Y + 1
            [Console]::SetCursorPosition(0, $newY)
            
            # Start spinner in background job
            $spinnerJob = Start-ThreadJob -Name "PSTask_$taskId" -ScriptBlock ${function:Update-Spinner} -ArgumentList @(
                $jobInfo.Position,
                $script:Config.Spinner.Chars,
                $script:Config.Spinner.Delay,
                $script:Config.Spinner.Color,
                $taskId
            )
            
            # Execute main task
            $output = . $ScriptBlock *>&1
            
            # Process output
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
            # Mark job as inactive
            $jobInfo.Active = $false
            
            # Clean up spinner job
            if ($spinnerJob) {
                Stop-Job -Job $spinnerJob -ErrorAction SilentlyContinue
                Remove-Job -Job $spinnerJob -ErrorAction SilentlyContinue
            }
            
            # Write final status
            Write-FinalStatus -Name $Name -Status $status -Indent $Indent
            
            # Remove job from collection
            $updatedJobs = [System.Collections.Concurrent.ConcurrentBag[hashtable]]::new()
            foreach ($item in $script:PSTaskJobs) {
                if ($item.Id -ne $taskId) {
                    $updatedJobs.Add($item)
                }
            }
            $script:PSTaskJobs = $updatedJobs
            
            # Restore cursor visibility
            [Console]::CursorVisible = $originalCursorVisible
            
            Add-PSTaskLog "TASK END - $Name - $status"
        }
    }
}