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

    .PARAMETER StopOnFailure
    When specified, re-throws the error after displaying failure status to cascade the failure to parent tasks.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [Parameter(Mandatory = $false)]
        [int]$Indent = 0,
        [Parameter(Mandatory = $false)]
        [switch]$StopOnFailure
    )

    process {
        Write-PSTaskLog "TASK START - $Name"

        # Save current cursor state
        $originalCursorVisible = [Console]::CursorVisible
        [Console]::CursorVisible = $false

        # Get current cursor position
        $taskPosition = $Host.UI.RawUI.CursorPosition

        # Generate unique ID for this task
        $taskId = [Guid]::NewGuid().ToString()

        # Initialize task state in synchronized hashtable
        $script:PSTaskJobs.Tasks[$taskId] = @{
            Active = $true
            Position = @{
                X = $taskPosition.X + $Indent
                Y = $taskPosition.Y
            }
            Name = $Name
        }

        $taskError = $null

        try {
            # Write initial task name
            Write-TaskName -Name $Name -Indent $Indent

            # Move cursor down one line for output
            $newY = $Host.UI.RawUI.CursorPosition.Y + 1
            [Console]::SetCursorPosition(0, $newY)

            # Start spinner in background job
            $spinnerJob = Start-ThreadJob -Name "PSTask_$taskId" -ScriptBlock {
                param($taskId, $scroll, $delay, $color, $jobs)
                
                try {
                    $i = 0
                    while ($jobs.Tasks[$taskId].Active) {
                        [ConsoleBufferWriter]::WriteTextAtPosition(
                            "$($scroll[$i])",
                            $jobs.Tasks[$taskId].Position.X,
                            $jobs.Tasks[$taskId].Position.Y,
                            $color
                        )
                        $i = ($i + 1) % $scroll.Length
                        Start-Sleep -Milliseconds $delay
                    }
                }
                catch {
                    # Log error but don't throw
                    Write-PSTaskLog "Spinner update error: $_" -Level "ERROR"
                }
            } -ArgumentList $taskId, $script:Config.Spinner.Chars, 
                            $script:Config.Spinner.Delay, 
                            $script:Config.Spinner.Color,
                            $script:PSTaskJobs

            # Execute main task
            $output = . $ScriptBlock *>&1

            # Process output with null check and string validation
            $output | Where-Object { $_ -ne $null } | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) {
                    $fullErrorMessage = Format-ErrorForLog $_
                    if (![string]::IsNullOrWhiteSpace($fullErrorMessage)) {
                        Write-PSTaskLog $fullErrorMessage -Level "ERROR"
                    }
                }
                else {
                    $message = $_.ToString()
                    if (![string]::IsNullOrWhiteSpace($message)) {
                        Write-PSTaskLog $message
                    }
                }
            }
            
            $status = "Success"
        }
        catch {
            $status = "Failure"
            $taskError = $_
            $fullErrorMessage = Format-ErrorForLog $_
            if (![string]::IsNullOrWhiteSpace($fullErrorMessage)) {
                Write-PSTaskLog $fullErrorMessage -Level "ERROR"
            }
        }
        finally {
            # Mark task as inactive
            $script:PSTaskJobs.Tasks[$taskId].Active = $false

            # Clean up spinner job
            if ($spinnerJob) {
                Stop-Job -Job $spinnerJob -ErrorAction SilentlyContinue
                Remove-Job -Job $spinnerJob -ErrorAction SilentlyContinue
            }

            # Write final status
            Write-FinalStatus -Name $Name -Status $status -Indent $Indent

            # Remove task from collection
            $script:PSTaskJobs.Tasks.Remove($taskId)

            # Restore cursor visibility
            [Console]::CursorVisible = $originalCursorVisible

            Write-PSTaskLog "TASK END - $Name - $status"
        }

        # Re-throw after cleanup so parent tasks can catch the failure
        if ($StopOnFailure -and $taskError) {
            throw $taskError
        }
    }
}