function Get-PSTaskLogFileName {
    <#
    .SYNOPSIS
    Generates a log file name based on the script name and configuration.

    .DESCRIPTION
    The Get-PSTaskLogFileName function creates a log file name using the script name, current date, and optional extra string.

    .PARAMETER LogName
    The name of the log file

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$LogName
    )

    process {
        $date = Get-Date -Format "yyyy-MMM-dd_HH-mm-ss"

        if ($LogName) {
            $fileName = "$date-$LogName.log"
        }
        else {
            $fileName = "$date.log"
        }

        return $fileName
    }
}