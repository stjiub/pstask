@{
    DefaultMode = "Spinner"
    DefaultVisibilityLevel = "Normal"
    TaskColor = "Cyan"
    MaxIndentationLevel = 4
    Spinner = @{
        Color = "Cyan"
        Chars = "/-\|/-\|"
        Delay = 100
    }
    StatusColors = @{
        Success = "Green"
        Failure = "Red"
        Default = "White"
    }
    StatusChars = @{
        Success = "[OK]"
        Failure = "[X]"
        Default = "-"
    }
    Logging = @{
        DefaultLogPath = $null
        LogHeaderFormat = @"
**********************
PSTask Log
Date: {0}
Script: {1}
Username: {2}
RunAs User: {3}
Machine: {4} ({5})
Host Application: {6}
Process ID: {7}
PSVersion: {8}
PSEdition: {9}
PSCompatibleVersions: {10}
BuildVersion: {11}
CLRVersion: {12}
WSManStackVersion: {13}
PSRemotingProtocolVersion: {14}
SerializationVersion: {15}
{16}**********************
"@
        LogFooterFormat = "========================================`nLog Ended: {0}`n========================================"
    }
}