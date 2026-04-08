function New-PSTask {
    <#
    .SYNOPSIS
    Creates and executes a new task with various output modes and logging capabilities.

    .DESCRIPTION
    The New-PSTask function allows you to create and execute tasks with different output modes (Spinner, Text, Verbose, Silent).
    It provides logging capabilities and can be customized using a configuration file. The function supports nested tasks
    and adjusts indentation accordingly. It also respects the visibility level set for PSTask operations.

    .PARAMETER Name
    The name of the task to be executed.

    .PARAMETER ScriptBlock
    The script block containing the code to be executed as part of the task.

    .PARAMETER Mode
    The output mode for the task. Valid values are "Spinner", "Text", "Verbose", and "Silent". 
    Default is the value specified in $script:Config.DefaultMode.

    .PARAMETER VisibilityLevel
    The visibility level for the task. This parameter is of type PSTaskVisibilityLevel enum.
    Default is [PSTaskVisibilityLevel]::Normal.

    .PARAMETER LogName
    The name of the log file to use for the New-PSTask.

    .PARAMETER LogPath
    The path where the log file should be created. If not specified, a default path will be used.

    .PARAMETER CustomFields
    A hashtable of custom fields to be added to the log header.

    .PARAMETER StopOnFailure
    When specified, a task failure will re-throw the error after displaying the failure status,
    causing parent tasks to stop executing subsequent child tasks. This enables cascading failure
    behavior where one failed task halts the entire pipeline.

    .EXAMPLE
    New-PSTask -Name "Initialize System" -ScriptBlock { Initialize-System } -LogName $MyInvocation.MyCommand.Name
    # This example creates a new task named "Initialize System" with the default Spinner output mode and logs it.

    .EXAMPLE
    New-PSTask -Name "Creating User Account" -ScriptBlock { Create-User -Username "JohnDoe" }
    # This example creates a new task named "Create User Account" with the default Spinner output mode.

    .EXAMPLE
    New-PSTask -Name "Update User" -ScriptBlock { Update-User -Username "JohnDoe" } -Mode "Text" 
    # This example creates a new task with Text output mode.

    .NOTES
    - You can call Stop-PSTaskLogging at the end of your script to clean up logging resources.
    - The function uses script-scoped variables for configuration and state management. Ensure these are properly initialized.
    - The function supports nested tasks and will adjust indentation for Spinner mode accordingly.

    .INPUTS
    None. You cannot pipe objects to New-PSTask.

    .OUTPUTS
    None. This function does not generate any output directly, but the task's scriptblock may produce output.

    .LINK
    Start-PSTaskLogging

    .LINK
    Stop-PSTaskLogging

    .LINK
    Set-PSTaskMode

    .LINK
    Set-PSTaskVisibilityLevel
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Spinner", "Text", "Silent", "Normal")]
        [string]$Mode = $script:PSTaskMode,

        [Parameter(Mandatory = $false)]
        [PSTaskVisibilityLevel]$VisibilityLevel = [PSTaskVisibilityLevel]::Normal,

        [Parameter(Mandatory = $false)]
        [string]$LogName,

        [Parameter(Mandatory = $false)]
        [string]$LogPath,

        [Parameter(Mandatory=$false)]
        [hashtable]$CustomFields,

        [Parameter(Mandatory=$false)]
        [switch]$StopOnFailure
    )
    
    process {
        # Determine effective StopOnFailure: explicit parameter OR inherited from parent
        $effectiveStopOnFailure = $StopOnFailure -or $script:PSTaskStopOnFailure
        $previousStopOnFailure = $script:PSTaskStopOnFailure

        # Propagate to child tasks if this task has StopOnFailure
        if ($effectiveStopOnFailure) {
            $script:PSTaskStopOnFailure = $true
        }

        try {
            $script:PSTaskNestingLevel++

            $loggingInitialized = $false
            if ($LogName -and -not $script:PSTaskLoggingState.IsLogging) {
                Start-PSTaskLogging -LogName $LogName -LogPath $LogPath -CustomFields $CustomFields
                $loggingInitialized = $true
            }
            elseif ($script:PSTaskLoggingState.IsLogging) {
                $script:PSTaskLoggingState.ReferenceCount++
            }

            $isVisible = $VisibilityLevel -ge $script:PSTaskVisibilityLevel
            $effectiveMode = if ($script:PSTaskDebugMode) { "Normal" }
                             elseif ($isVisible) { $Mode }
                             else { "Silent" }

            switch ($effectiveMode) {
                "Spinner" {
                    # Calculate intent level
                    $indentLevel = [Math]::Min($script:PSTaskNestingLevel - 1, $script:Config.MaxIndentationLevel)
                    $indent = $indentLevel * 4  # 4 spaces per indentation level
                    Invoke-SpinnerTask -Name $Name -ScriptBlock $ScriptBlock -Indent $indent -StopOnFailure:$effectiveStopOnFailure
                }
                "Text" { Invoke-TextTask -Name $Name -ScriptBlock $ScriptBlock -StopOnFailure:$effectiveStopOnFailure }
                "Normal" { Invoke-NormalTask -Name $Name -ScriptBlock $ScriptBlock }
                "Silent" { Invoke-SilentTask -Name $Name -ScriptBlock $ScriptBlock }
            }
        }
        finally {
            # Restore previous StopOnFailure state so sibling scopes aren't affected
            $script:PSTaskStopOnFailure = $previousStopOnFailure

            # Decrease the reference count or stop logging if this task initialized it
            if ($loggingInitialized) {
                Stop-PSTaskLogging
            }
            elseif ($script:PSTaskLoggingState.IsLogging) {
                $script:PSTaskLoggingState.ReferenceCount--
                if ($script:PSTaskLoggingState.ReferenceCount -le 0) {
                    Stop-PSTaskLogging
                }
            }
            $script:PSTaskNestingLevel--
        }
    }
}