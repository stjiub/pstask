enum PSTaskVisibilityLevel {
    Debug = 0
    Verbose = 1
    Normal = 2
    Important = 3
    Critical = 4
}

$script:ModuleRoot = $PSScriptRoot
$script:ModuleConfigFolder = Join-Path $script:ModuleRoot 'config'
$script:ModuleClassFolder = Join-Path $script:ModuleRoot 'class'
$script:ModuleConfigFile = Join-Path $script:ModuleConfigFolder 'main.psd1'

# Start-ThreadJob is built in to PowerShell 7+, but Windows PowerShell 5.1 needs the gallery module
if (-not (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue)) {
    try {
        Import-Module ThreadJob -ErrorAction Stop
    }
    catch {
        throw "PSTask requires the ThreadJob module on Windows PowerShell 5.1. Install it with: Install-Module ThreadJob -Scope CurrentUser"
    }
}

$Public  = @(Get-ChildItem -Path (Join-Path $script:ModuleRoot 'public') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path (Join-Path $script:ModuleRoot 'private') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue)

foreach ($ps1 in @($Public + $Private)) {
    try {
        . $ps1.FullName
    }
    catch {
        Write-Error "Failed to import function $($ps1.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.BaseName

if (-not ('ConsoleBufferWriter' -as [type])) {
    Add-Type -Path (Join-Path $script:ModuleClassFolder 'ConsoleBufferWriter.cs')
}

$script:PSTaskJobs = [hashtable]::Synchronized(@{
    Tasks = @{}
})
$script:PSTaskLoggingState = @{
    IsLogging = $false
    LogPath = $null
    LastLogPath = $null
    ReferenceCount = 0
}
$script:PSTaskNestingLevel = 0
$script:PSTaskStopOnFailure = $false
$script:PSTaskDebugMode = $false

$script:Config = Import-PowerShellDataFile -Path $script:ModuleConfigFile

$script:PSTaskMode = $script:Config.DefaultMode
$script:PSTaskVisibilityLevel = $script:Config.DefaultVisibilityLevel
