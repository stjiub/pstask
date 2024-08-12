function Format-ErrorForLog {
    <#
    .SYNOPSIS
    Formats an error record for logging.

    .DESCRIPTION
    The Format-ErrorForLog function takes an ErrorRecord object and formats it into a multi-line string
    suitable for detailed error logging.

    .PARAMETER ErrorRecord
    The ErrorRecord object to be formatted.
    #>

    [CmdletBinding()]
    param (
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    process {
        $errorLines = @(
            "Exception Type: $($ErrorRecord.Exception.GetType().FullName)"
            "Exception Message: $($ErrorRecord.Exception.Message)"
            "Error Details: $($ErrorRecord.ErrorDetails)"
            "Script Line: $($ErrorRecord.InvocationInfo.ScriptLineNumber)"
            "Script Name: $($ErrorRecord.InvocationInfo.ScriptName)"
            "Invocation Name: $($ErrorRecord.InvocationInfo.InvocationName)"
            "Position Message: $($ErrorRecord.InvocationInfo.PositionMessage)"
            "Stack Trace:"
            $ErrorRecord.ScriptStackTrace
        )
        return $errorLines -join [Environment]::NewLine
    }
}