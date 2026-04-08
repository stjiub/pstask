function Show-PSTaskLog {
    <#
    .SYNOPSIS
    Displays the PSTask log file with color-coded formatting.

    .DESCRIPTION
    Reads the current, last, or specified log file and displays entries with color coding
    based on log level. Task boundaries, errors, and informational messages are visually
    distinguished for easier reading.

    .PARAMETER LogPath
    Path to a specific log file to display. If not specified, uses the active log or the
    last completed log.

    .PARAMETER Tail
    Show only the last N lines of the log.

    .PARAMETER Level
    Filter log entries by minimum level. Valid values are INFO, WARNING, and ERROR.
    Default shows all entries.

    .EXAMPLE
    Show-PSTaskLog
    # Displays the current or last log with color formatting.

    .EXAMPLE
    Show-PSTaskLog -Tail 20
    # Displays the last 20 lines of the log.

    .EXAMPLE
    Show-PSTaskLog -Level ERROR
    # Displays only error entries from the log.

    .EXAMPLE
    Show-PSTaskLog -LogPath "C:\Logs\MyScript_2026-04-08.log"
    # Displays a specific log file.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$LogPath,

        [Parameter(Mandatory = $false)]
        [int]$Tail,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level
    )

    process {
        # Resolve log path: explicit > active > last
        if (-not $LogPath) {
            if ($script:PSTaskLoggingState.IsLogging) {
                $LogPath = $script:PSTaskLoggingState.LogPath
            }
            elseif ($script:PSTaskLoggingState.LastLogPath) {
                $LogPath = $script:PSTaskLoggingState.LastLogPath
            }
            else {
                Write-Warning "No log file available. Specify a path with -LogPath."
                return
            }
        }

        if (-not (Test-Path $LogPath)) {
            Write-Warning "Log file not found: $LogPath"
            return
        }

        $lines = Get-Content $LogPath

        if ($Tail) {
            $lines = $lines | Select-Object -Last $Tail
        }

        # Level filtering priority
        $levelPriority = @{ "INFO" = 0; "WARNING" = 1; "ERROR" = 2 }
        $minPriority = if ($Level) { $levelPriority[$Level] } else { 0 }

        foreach ($line in $lines) {
            # Parse structured log entries
            if ($line -match "^\[(.*?)\] \[(INFO|WARNING|ERROR)\] (.*)") {
                $entryLevel = $matches[2]
                $message = $matches[3]

                # Apply level filter
                if ($levelPriority[$entryLevel] -lt $minPriority) {
                    continue
                }

                # Color based on content and level
                if ($entryLevel -eq "ERROR") {
                    Write-Host $line -ForegroundColor Red
                }
                elseif ($entryLevel -eq "WARNING") {
                    Write-Host $line -ForegroundColor Yellow
                }
                elseif ($message -match "^TASK START - ") {
                    Write-Host $line -ForegroundColor Cyan
                }
                elseif ($message -match "^TASK END - .* - Success") {
                    Write-Host $line -ForegroundColor Green
                }
                elseif ($message -match "^TASK END - .* - Warning") {
                    Write-Host $line -ForegroundColor Yellow
                }
                elseif ($message -match "^TASK END - .* - Failure") {
                    Write-Host $line -ForegroundColor Red
                }
                else {
                    Write-Host $line
                }
            }
            else {
                # Header/footer/unstructured lines
                Write-Host $line -ForegroundColor DarkGray
            }
        }
    }
}
