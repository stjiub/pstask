function Write-FinalStatus {
    <#
    .SYNOPSIS
    Writes the final status of a task to the console.

    .DESCRIPTION
    The Write-FinalStatus function writes the final status (success or failure) of a task to the console.

    .PARAMETER Name
    The name of the task.

    .PARAMETER Status
    The final status of the task.

    .PARAMETER Indent
    The number of spaces to indent the status message. Default is 0.
    #>

    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Status,
        [int]$Indent = 0
    )

    process {
        # Use if-else instead of null-coalescing operator
        if ($script:Config.StatusChars.$Status) {
            $char = $script:Config.StatusChars.$Status
        } else {
            $char = $script:Config.StatusChars.Default
        }
        
        if ($script:Config.StatusColors.$Status) {
            $statusColorName = $script:Config.StatusColors.$Status
        } else {
            $statusColorName = $script:Config.StatusColors.Default
        }
        
        $statusColor = [System.ConsoleColor]::$statusColorName

        [ConsoleBufferWriter]::WriteTextAtPosition("$char $Name", $taskPosition.X + $Indent, $taskPosition.Y, $statusColor)
    }
}