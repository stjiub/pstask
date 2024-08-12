function Stop-PSTaskLogging {
    <#
    .SYNOPSIS
    Stops the PSTask logging for the current thread.

    .DESCRIPTION
    The Stop-PSTaskLogging function cleans up the logging resources associated with the current thread.
    It decrements the reference count for logging and, when the count reaches zero, finalizes the log file by writing a footer.
    This function should be called at the end of a script that uses Start-PSTaskLogging to ensure proper resource management.

    .EXAMPLE
    Stop-PSTaskLogging
    # This example stops the PSTask logging for the current thread.

    .NOTES
    It's recommended to call this function in a finally block or at the very end of your script to ensure logging is properly closed even if exceptions occur.
    The function uses script-scoped variables to manage logging state, so ensure these are properly initialized before calling this function.

    .INPUTS
    None. You cannot pipe objects to Stop-PSTaskLogging.

    .OUTPUTS
    None. This function does not generate any output.

    .LINK
    Start-PSTaskLogging
    #>

    [CmdletBinding()]
    param()

    process {
        if (-not $script:PSTaskLoggingState.IsLogging) {
            Write-Verbose "Logging is not active. Nothing to stop."
            return
        }
    
        $script:PSTaskLoggingState.ReferenceCount--
    
        if ($script:PSTaskLoggingState.ReferenceCount -le 0) {
            $script:PSTaskLoggingState.IsLogging = $false
            $logPath = $script:PSTaskLoggingState.LogPath
            $script:PSTaskLoggingState.LogPath = $null
            $script:PSTaskLoggingState.ReferenceCount = 0
    
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $footer = $script:Config.Logging.LogFooterFormat -f $timestamp
            $footer | Out-File -FilePath $logPath -Append
            Write-Verbose "Logging stopped. Log file: $logPath"
        }
        else {
            Write-Verbose "Decreased logging reference count to $($script:PSTaskLoggingState.ReferenceCount)"
        }
    }
}