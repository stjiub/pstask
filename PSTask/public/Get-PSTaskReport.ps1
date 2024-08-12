function Get-PSTaskReport {
    <#
    .SYNOPSIS
    Generates a report from a PSTask log file.

    .DESCRIPTION
    The Get-PSTaskReport function reads a PSTask log file and generates a detailed report of the tasks executed.
    It provides information such as script name, user, start and end times, task statuses, and individual task details.
    The report can be returned as an object for further processing or displayed directly in the console.

    .PARAMETER LogFilePath
    The full path to the PSTask log file to analyze. This parameter is mandatory.

    .PARAMETER Format
    The output format of the report. Valid values are "Object" and "Console". 
    - "Object" returns a PSCustomObject that can be further processed or formatted.
    - "Console" displays a formatted report directly in the console.
    Default is "Object".

    .EXAMPLE
    Get-PSTaskReport -LogFilePath "C:\Logs\MyScript.log"
    # This example generates a report object from the specified log file.

    .EXAMPLE
    Get-PSTaskReport -LogFilePath "C:\Logs\MyScript.log" -Format "Console"
    # This example displays a formatted report in the console for the specified log file.

    .INPUTS
    None. You cannot pipe objects to Get-PSTaskReport.

    .OUTPUTS
    If Format is set to "Object", the function returns a PSCustomObject containing the report data.
    If Format is set to "Console", the function outputs a formatted report to the console and does not return any objects.

    .NOTES
    - The function expects the log file to be in a specific format produced by PSTask logging.
    - Make sure the log file path is accessible and the file exists before running this function.
    - The console output uses color coding for better readability:
    - Green for successful tasks
    - Red for failed tasks
    - Yellow for task names and general information
    - Cyan for section headers

    .LINK
    New-PSTask

    .LINK
    Start-PSTaskLogging

    .LINK
    Stop-PSTaskLogging
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFilePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Object", "Console")]
        [string]$Format = "Object"
    )

    process {

        if (-not (Test-Path $LogFilePath)) {
            throw "Log file not found: $LogFilePath"
        }

        $logContent = Get-Content $LogFilePath

        $report = @{
            ScriptName = ""
            StartTime = $null
            EndTime = $null
            User = ""
            Tasks = @()
            TotalTasks = 0
            SuccessfulTasks = 0
            FailedTasks = 0
        }

        $currentTask = $null

        foreach ($line in $logContent) {
            if ($line -match '^\[(?<timestamp>.*?)\] \[(?<level>.*?)\] (?<message>.*)$') {
                $timestamp = [DateTime]::ParseExact($matches.timestamp, "yyyy-MM-dd HH:mm:ss", $null)
                $level = $matches.level
                $message = $matches.message

                if ($message -match '^Script: (.*)$') {
                    $report.ScriptName = $matches[1]
                }
                elseif ($message -match '^User: (.*)$') {
                    $report.User = $matches[1]
                }
                elseif ($message -match 'TASK START - (.*)$') {
                    if ($currentTask) {
                        $report.Tasks += $currentTask
                    }
                    $taskName = $matches[1]
                    $currentTask = @{
                        Name = $taskName
                        StartTime = $timestamp
                        EndTime = $null
                        Status = "Running"
                        Messages = @()
                    }
                }
                elseif ($message -match 'TASK END - (.*) - (.*)$') {
                    if ($currentTask) {
                        $currentTask.EndTime = $timestamp
                        $currentTask.Status = $matches[2]
                        $report.Tasks += $currentTask
                        $currentTask = $null

                        if ($matches[2] -eq "Success") {
                            $report.SuccessfulTasks++
                        }
                        else {
                            $report.FailedTasks++
                        }
                    }
                }
                elseif ($currentTask) {
                    $currentTask.Messages += @{
                        Timestamp = $timestamp
                        Level = $level
                        Message = $message
                    }
                }
            }
        }

        if ($currentTask) {
            $report.Tasks += $currentTask
        }

        $report.TotalTasks = $report.Tasks.Count
        $report.StartTime = $report.Tasks[0].StartTime
        $report.EndTime = $report.Tasks[-1].EndTime

        if ($Format -eq "Object") {
            return [PSCustomObject]$report
        }
        else {
            # Console output formatting
            Write-Host "PSTask Report" -ForegroundColor Cyan
            Write-Host "=============" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Script: $($report.ScriptName)" -ForegroundColor Yellow
            Write-Host "User: $($report.User)" -ForegroundColor Yellow
            Write-Host "Start Time: $($report.StartTime)" -ForegroundColor Yellow
            Write-Host "End Time: $($report.EndTime)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Summary:" -ForegroundColor Cyan
            Write-Host "--------" -ForegroundColor Cyan
            Write-Host "Total Tasks: $($report.TotalTasks)"
            Write-Host "Successful Tasks: $($report.SuccessfulTasks)" -ForegroundColor Green
            Write-Host "Failed Tasks: $($report.FailedTasks)" -ForegroundColor Red
            Write-Host ""
            Write-Host "Task Details:" -ForegroundColor Cyan
            Write-Host "------------" -ForegroundColor Cyan

            foreach ($task in $report.Tasks) {
                $statusColor = if ($task.Status -eq "Success") { "Green" } else { "Red" }
                Write-Host ""
                Write-Host "Task: $($task.Name)" -ForegroundColor Yellow
                Write-Host "Status: $($task.Status)" -ForegroundColor $statusColor
                Write-Host "Duration: $(($task.EndTime - $task.StartTime).TotalSeconds) seconds"
                
                if ($task.Messages.Count -gt 0) {
                    Write-Host "Messages:"
                    foreach ($msg in $task.Messages) {
                        $messageColor = switch ($msg.Level) {
                            "ERROR" { "Red" }
                            "WARNING" { "Yellow" }
                            default { "White" }
                        }
                        Write-Host "  [$($msg.Timestamp.ToString('HH:mm:ss'))] $($msg.Message)" -ForegroundColor $messageColor
                    }
                }
            }
        }
    }
}