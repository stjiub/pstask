function Set-PSTaskDebug {
    <#
    .SYNOPSIS
    Enables or disables PSTask debug mode.

    .DESCRIPTION
    When debug mode is enabled, all tasks are forced to use Normal mode regardless of their
    configured mode. This allows output to flow naturally to the console, making it easier
    to debug scripts that use PSTask by seeing Write-Debug, Write-Verbose, and other stream
    output in real time instead of having it captured or hidden.

    .PARAMETER Enabled
    Enables debug mode, forcing all tasks to Normal mode.

    .PARAMETER Disabled
    Disables debug mode, restoring normal PSTask mode behavior.

    .EXAMPLE
    Set-PSTaskDebug -Enabled
    # All subsequent tasks will run in Normal mode for debugging.

    .EXAMPLE
    Set-PSTaskDebug -Disabled
    # Restores configured mode behavior.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Enable")]
        [switch]$Enabled,

        [Parameter(Mandatory = $true, ParameterSetName = "Disable")]
        [switch]$Disabled
    )

    process {
        if ($Enabled) {
            $script:PSTaskDebugMode = $true
            Write-Verbose "PSTask debug mode enabled. All tasks will use Normal mode."
        }
        else {
            $script:PSTaskDebugMode = $false
            Write-Verbose "PSTask debug mode disabled. Tasks will use their configured mode."
        }
    }
}
