function Add-PSTaskLog {
    <#
    .SYNOPSIS
    Adds a log entry to the PSTask log file.

    .DESCRIPTION
    The Add-PSTaskLog function writes a new entry to the PSTask log file with a timestamp and specified log level.

    .PARAMETER Message
    The message to be logged.

    .PARAMETER Level
    The log level for the message. Valid values are "INFO", "WARNING", and "ERROR". Default is "INFO".
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    process {
        if (-not $script:PSTaskLoggingState.IsLogging) {
            Write-Verbose "Logging is not active. Message not logged: $Message"
            return
        }
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        $logEntry | Out-File -FilePath $script:PSTaskLoggingState.LogPath -Append
        Write-Verbose $logEntry
        
    }
}