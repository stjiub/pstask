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
        LogHeaderFormat = "========================================`nScript: {0}`nDate: {1}`nUser: {2}`nLog File: {3}`n========================================"
        LogFooterFormat = "========================================`nLog Ended: {0}`n========================================"
    }
}