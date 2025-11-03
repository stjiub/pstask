
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

    .PARAMETER LogPathOverride
    An optional full path (including filename) for the log file. When specified, this overrides PSTask's internal file naming logic and uses the exact path provided. Cannot be used together with LogPath.

    .PARAMETER CustomFields
    A hashtable of custom fields to be added to the log header. This allows for additional context or metadata to be included in the log.

    .EXAMPLE
    Start-PSTaskLogging -LogName "MyScript"
    # This initializes logging for "MyScript" using the default log path.

    .EXAMPLE
    Start-PSTaskLogging -LogName "MyScript" -LogPath "C:\Logs" -CustomFields @{Version="1.0"; Environment="Production"}
    # This initializes logging for "MyScript" in the specified path with custom fields for version and environment.

    .EXAMPLE
    Start-PSTaskLogging -LogName "MyScript" -LogPathOverride "C:\Logs\CustomLog.log"
    # This initializes logging for "MyScript" using the exact file path specified, bypassing the automatic filename generation.

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
        [string]$LogPathOverride,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$CustomFields
    )

    process {
        if ($script:PSTaskLoggingState.IsLogging) {
            $script:PSTaskLoggingState.ReferenceCount++
            Write-Verbose "Logging already active. Increased reference count to $($script:PSTaskLoggingState.ReferenceCount)"
            return
        }

        # Validate that LogPath and LogPathOverride are not both specified
        if ($LogPath -and $LogPathOverride) {
            throw "Cannot specify both LogPath and LogPathOverride parameters. Use LogPathOverride to specify the complete file path, or LogPath to specify only the directory."
        }

        # Use LogPathOverride if specified, otherwise use the existing logic
        if ($LogPathOverride) {
            $LogPath = $LogPathOverride
        }
        else {
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
        }

        $script:PSTaskLoggingState.IsLogging = $true
        $script:PSTaskLoggingState.LogPath = $LogPath
        $script:PSTaskLoggingState.ReferenceCount = 1

        # Collect system information
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $user = $currentIdentity.Name
        $runAsUser = $currentIdentity.Name  # In most cases this is the same unless impersonating
        $machineName = $env:COMPUTERNAME
        $osVersion = [System.Environment]::OSVersion.VersionString
        $hostApp = $Host.Name
        if ($MyInvocation.PSCommandPath) {
            $hostApp = $MyInvocation.PSCommandPath
        } elseif ($Host.Name -eq "ConsoleHost") {
            $hostApp = (Get-Process -Id $PID).Path
        }
        $processId = $PID
        $psVersion = if ($PSVersionTable.PSVersion) { $PSVersionTable.PSVersion.ToString() } else { "N/A" }
        $edition = if ($PSVersionTable.PSEdition) { $PSVersionTable.PSEdition } else { "Desktop" }
        $psCompatibleVersions = if ($PSVersionTable.PSCompatibleVersions) { $PSVersionTable.PSCompatibleVersions -join ", " } else { "N/A" }
        $buildVersion = if ($PSVersionTable.BuildVersion) { $PSVersionTable.BuildVersion.ToString() } else { "N/A" }
        $clrVersion = if ($PSVersionTable.CLRVersion) { $PSVersionTable.CLRVersion.ToString() } else { "N/A" }
        $wsManStackVersion = if ($PSVersionTable.WSManStackVersion) { $PSVersionTable.WSManStackVersion.ToString() } else { "N/A" }
        $psRemotingProtocolVersion = if ($PSVersionTable.PSRemotingProtocolVersion) { $PSVersionTable.PSRemotingProtocolVersion.ToString() } else { "N/A" }
        $serializationVersion = if ($PSVersionTable.SerializationVersion) { $PSVersionTable.SerializationVersion.ToString() } else { "N/A" }

        # Format custom fields if provided
        $customFieldsString = ""
        if ($CustomFields) {
            $customFieldsString = ($CustomFields.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)`n" }) -join ""
        }

        $header = $script:Config.Logging.LogHeaderFormat -f $timestamp, $LogName, $user, $runAsUser, $machineName, $osVersion, $hostApp, $processId, $psVersion, $edition, $psCompatibleVersions, $buildVersion, $clrVersion, $wsManStackVersion, $psRemotingProtocolVersion, $serializationVersion, $customFieldsString
        $header | Out-File -FilePath $LogPath -Append
        Write-Verbose "Logging initialized. Log file: $($script:PSTaskLoggingState.LogPath)"
    }
}