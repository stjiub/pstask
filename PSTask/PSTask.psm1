$script:ModuleRoot = $PSScriptRoot
$script:ModuleConfigFolder = "$script:ModuleRoot\config"
$script:ModuleClassFolder = "$script:ModuleRoot\class"
$script:ModuleConfigFile = "$script:ModuleConfigFolder\main.psd1"

$Public  = @(Get-ChildItem -Path "$script:ModuleRoot\public\" -Include '*.ps1' -Recurse -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path "$script:ModuleRoot\private\" -Include '*.ps1' -Recurse -ErrorAction SilentlyContinue)
$Class = @(Get-ChildItem -Path $script:ModuleClassFolder -Include '*.ps1' -Recurse -ErrorAction SilentlyContinue)

# Load all module functions
foreach ($ps1 in @($Public + $Private + $Class)) {
    try {
        . $ps1.FullName
    } 
    catch {
        Write-Error "Failed to import function $($ps1.FullName): $_"
    }
}

# Export public functions so that they can be called
Export-ModuleMember -Function $Public.Basename

# Load ConsoleBufferWriter class
Add-Type -Path "$($script:ModuleClassFolder)\ConsoleBufferWriter.cs"

# Initialize script vars
$script:PSTaskJobs = [System.Collections.Concurrent.ConcurrentBag[hashtable]]::new()
$script:PSTaskLoggingState = @{
    IsLogging = $false
    LogPath = $null
    ReferenceCount = 0
}
$script:PSTaskNestingLevel = 0

# Load main module config file
$script:Config = Import-PowerShellDataFile -Path $script:ModuleConfigFile

# Set defaults from config file
$script:PSTaskMode = $script:Config.DefaultMode
$script:PSTaskVisibilityLevel = $script:Config.DefaultVisibilityLevel

# Assign Visibility Levels
enum PSTaskVisibilityLevel {
    Debug = 0
    Verbose = 1
    Normal = 2
    Important = 3
    Critical = 4
}