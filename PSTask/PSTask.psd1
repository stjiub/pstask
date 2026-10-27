@{
    RootModule            = 'PSTask.psm1'
    ModuleVersion         = '0.3.1'
    GUID                  = '0bd4f84a-fde9-44ca-90d1-6c10b44b2e30'
    Author                = 'stjiub'
    Copyright             = '(c) 2024 stjiub. All rights reserved.'
    Description           = 'Run script blocks as named tasks with a live console spinner, nested task display, and automatic logging.'
    PowerShellVersion     = '5.1'
    CompatiblePSEditions  = @('Desktop', 'Core')

    FunctionsToExport     = @(
        'New-PSTask'
        'Set-PSTaskDebug'
        'Set-PSTaskMode'
        'Set-PSTaskVisibilityLevel'
        'Show-PSTaskLog'
        'Show-PSTaskTree'
        'Start-PSTaskLogging'
        'Stop-PSTaskLogging'
        'Write-PSTaskLog'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()

    PrivateData           = @{
        PSData = @{
            Tags       = @('Task', 'Spinner', 'Logging', 'Console', 'Progress', 'Windows')
            LicenseUri = 'https://github.com/stjiub/pstask/blob/master/LICENSE'
            ProjectUri = 'https://github.com/stjiub/pstask'
        }
    }
}
