function Update-Spinner {
    <#
    .SYNOPSIS
    Updates the spinner animation for a running task.

    .DESCRIPTION
    The Update-Spinner function is responsible for updating the spinner animation in the console
    for a task that's currently running.

    .PARAMETER Position
    A PSCustomObject containing the X and Y coordinates for the spinner in the console.

    .PARAMETER Scroll
    The string of characters to use for the spinner animation.

    .PARAMETER Delay
    The delay in milliseconds between each frame of the spinner animation.

    .PARAMETER Color
    The color to use for the spinner text.

    .PARAMETER TaskId
    The unique identifier for the task this spinner belongs to.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Position,
        [Parameter(Mandatory = $true)]
        [string]$Scroll,
        [Parameter(Mandatory = $true)]
        [int]$Delay,
        [Parameter(Mandatory = $true)]
        [System.ConsoleColor]$Color,
        [Parameter(Mandatory = $true)]
        [string]$TaskId
    )
    
    process {
        try {
            $i = 0
            # Find our job info
            $jobInfo = $script:PSTaskJobs | Where-Object { $_.Id -eq $TaskId }
            
            if (-not $jobInfo) {
                return
            }
            
            while ($jobInfo.Active) {
                [ConsoleBufferWriter]::WriteTextAtPosition(
                    "$($Scroll[$i])", 
                    $Position.X, 
                    $Position.Y, 
                    $Color
                )
                $i = ($i + 1) % $Scroll.Length
                Start-Sleep -Milliseconds $Delay
                
                # Refresh job info reference
                $jobInfo = $script:PSTaskJobs | Where-Object { $_.Id -eq $TaskId }
                if (-not $jobInfo) {
                    break
                }
            }
        }
        catch {
            # Log error but don't throw to avoid breaking the main task
            Write-PSTaskLog "Spinner update error: $_" -Level "ERROR"
        }
    }
}