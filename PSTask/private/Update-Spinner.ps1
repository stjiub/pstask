function Update-Spinner {
    <#
    .SYNOPSIS
    Updates the spinner animation for a running task.

    .DESCRIPTION
    The Update-Spinner function is responsible for updating the spinner animation in the console
    for a task that's currently running.

    .PARAMETER Position
    A PSCustomObject containing the X and Y coordinates for the spinner in the console.

    .PARAMETER Name
    The name of the task associated with this spinner.

    .PARAMETER Scroll
    The string of characters to use for the spinner animation.

    .PARAMETER Delay
    The delay in milliseconds between each frame of the spinner animation.

    .PARAMETER Color
    The color to use for the spinner text.
    #>
    
    [CmdletBinding()]
    param(
        [PSCustomObject]$Position,
        [string]$Scroll,
        [int]$Delay,
        [System.ConsoleColor]$Color
    )

    process {
        $i = 0
        do {
            [ConsoleBufferWriter]::WriteTextAtPosition("$($Scroll[$i])", $Position.X, $Position.Y, $Color)
            $i = ($i + 1) % $Scroll.Length
            Start-Sleep -Milliseconds $Delay
        } while ($true)
    }
}