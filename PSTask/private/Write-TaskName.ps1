function Write-TaskName {
    <#
    .SYNOPSIS
    Writes the task name to the console.

    .DESCRIPTION
    The Write-TaskName function writes the name of a task to the console at a specific position.

    .PARAMETER Name
    The name of the task to write.

    .PARAMETER Char
    The character to use before the task name. Default is "-".

    .PARAMETER Indent
    The number of spaces to indent the task name. Default is 0.
    #>

    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Char = "-",
        [int]$Indent = 0
    )

    process {
        [ConsoleBufferWriter]::WriteTextAtPosition("$Char $Name", $taskPosition.X + $Indent, $taskPosition.Y, $script:Config.TaskColor)
    }
}