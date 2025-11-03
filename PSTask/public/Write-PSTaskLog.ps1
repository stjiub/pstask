function Write-PSTaskLog {
    <#
    .SYNOPSIS
    Writes a log entry to the PSTask log file.

    .DESCRIPTION
    The Write-PSTaskLog function writes a new entry to the PSTask log file with a timestamp and specified log level.

    .PARAMETER Message
    The message to be logged.

    .PARAMETER Level
    The log level for the message. Valid values are "INFO", "WARNING", and "ERROR". Default is "INFO".

    .EXAMPLE
    PS> Write-PSTaskLog "This text will be added to the log file"

    .EXAMPLE
    PS> Write-PSTaskLog -Level "Error" -Message "This is an error"
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