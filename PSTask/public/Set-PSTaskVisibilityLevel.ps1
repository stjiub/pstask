function Set-PSTaskVisibilityLevel {
    <#
    .SYNOPSIS
    Sets the visibility level for PSTask operations.

    .DESCRIPTION
    The Set-PSTaskVisibilityLevel function allows you to set the visibility level for PSTask operations. This function modifies a script-scoped variable that determines how verbose the output of PSTask operations will be.

    .PARAMETER Level
    Specifies the visibility level to set. This parameter is mandatory and accepts values from the PSTaskVisibilityLevel enumeration.

    .EXAMPLE
    Set-PSTaskVisibilityLevel -Level Verbose
    # This sets the PSTask visibility level to Verbose, which will provide more detailed output during PSTask operations.

    .EXAMPLE
    Set-PSTaskVisibilityLevel -Level Normal
    # This sets the PSTask visibility level to Normal, which provides standard output during PSTask operations.

    .NOTES
    The function uses a script-scoped variable $script:PSTaskVisibilityLevel to store the visibility level. This allows other functions within the same script to access and use this visibility level.

    .INPUTS
    None. You cannot pipe objects to Set-PSTaskVisibilityLevel.

    .OUTPUTS
    None. This function does not generate any output.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSTaskVisibilityLevel]$Level
    )
    process {
        $script:PSTaskVisibilityLevel = $Level
        Write-Verbose "PSTask Visibility level set to $Level"
    }
}