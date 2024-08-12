function Set-PSTaskMode {
    <#
    .SYNOPSIS
    Sets the PSTask output mode.

    .DESCRIPTION
    The Set-PSTaskMode function sets the default PSTask output mode for the current PowerShell session.
    This allows you to avoid specifying the mode every time you start a new PSTask. 
    You can still specify a different mode for an individual task if needed.
    To permanently change the default PSTask output mode, refer to the main.psd1 config file.

    .PARAMETER Mode
    The PSTask output mode to set. Valid options are "Silent", "Text", "Verbose", and "Spinner".

    .EXAMPLE
    Set-PSTaskMode -Mode "Silent"
    # This example sets the PSTask output mode to Silent for the current session.

    .EXAMPLE
    Set-PSTaskMode -Mode "Verbose"
    # This example sets the PSTask output mode to Verbose for the current session.

    .NOTES
    The function uses a script-scoped variable $script:PSTaskMode to store the mode. 
    Ensure this variable is properly initialized in your script or module.

    .INPUTS
    None. You cannot pipe objects to Set-PSTaskMode.

    .OUTPUTS
    None. This function does not generate any output.
    #>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Silent","Text","Verbose","Spinner")]
        [string]$Mode
    )

    process {
        $script:PSTaskMode = $Mode
    }
}