
function Start-PSTaskLogging {
    <#
    .SYNOPSIS
    Initializes logging for a PSTask script.

    .DESCRIPTION
    The Start-PSTaskLogging function sets up logging for a script using PSTask. It creates the necessary log file and writes the initial header. If logging is already active, it increments a reference count instead of initializing a new log.

    .PARAMETER LogName
    The name of the log for which logging is being initialized. This parameter is mandatory.

    .PARAMETER LogPath
    An optional custom path for the log file. If not specified, the function will use the default log path from the script configuration or the current location.

    .PARAMETER CustomFields
    A hashtable of custom fields to be added to the log header. This allows for additional context or metadata to be included in the log.

    .EXAMPLE
    Start-PSTaskLogging -LogName "MyScript"
    # This initializes logging for "MyScript" using the default log path.

    .EXAMPLE
    Start-PSTaskLogging -LogName "MyScript" -LogPath "C:\Logs" -CustomFields @{Version="1.0"; Environment="Production"}
    # This initializes logging for "MyScript" in the specified path with custom fields for version and environment.

    .NOTES
    The function uses script-scoped variables ($script:PSTaskLoggingState and $script:Config) to manage logging state and configuration. Ensure these are properly initialized before calling this function.

    .INPUTS
    None. You cannot pipe objects to Start-PSTaskLogging.

    .OUTPUTS
    None. This function does not generate any output.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogName,
        [Parameter(Mandatory=$false)]
        [string]$LogPath,
        [Parameter(Mandatory=$false)]
        [hashtable]$CustomFields
    )

    process {
        if ($script:PSTaskLoggingState.IsLogging) {
            $script:PSTaskLoggingState.ReferenceCount++
            Write-Verbose "Logging already active. Increased reference count to $($script:PSTaskLoggingState.ReferenceCount)"
            return
        }

        $newLogName = Get-PSTaskLogFileName -LogName $LogName

        if ((-not $LogPath) -and ($script:Config.Logging.DefaultLogPath)) {
            $LogPath = Join-Path $script:Config.Logging.DefaultLogPath $newLogName
        }
        elseif (-not $LogPath) {
            $LogPath = Join-Path (Get-Location).Path $newLogName
        }
        else {
            $LogPath = Join-Path $LogPath $newLogName
        }

        $script:PSTaskLoggingState.IsLogging = $true
        $script:PSTaskLoggingState.LogPath = $LogPath
        $script:PSTaskLoggingState.ReferenceCount = 1

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $customFieldsString = if ($CustomFields) { $CustomFields.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" } | Out-String } else { "" }
        $header = $script:Config.Logging.LogHeaderFormat -f $LogName, $timestamp, $user, $LogPath, $customFieldsString
        $header | Out-File -FilePath $LogPath -Append
        Write-Verbose "Logging initialized. Log file: $($script:PSTaskLoggingState.LogPath)"
    }
}