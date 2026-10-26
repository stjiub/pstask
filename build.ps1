<#
.SYNOPSIS
Build tasks for PSTask: static analysis, tests, and publishing.

.EXAMPLE
./build.ps1 -Task Test

.EXAMPLE
./build.ps1 -Task Publish -NuGetApiKey $key
#>
[CmdletBinding()]
param(
    [ValidateSet('Analyze', 'Test', 'Publish')]
    [string]$Task = 'Test',

    [switch]$Coverage,

    [string]$NuGetApiKey
)

$ErrorActionPreference = 'Stop'
$moduleRoot = Join-Path $PSScriptRoot 'PSTask'

function Invoke-Analyze {
    $results = Get-ChildItem -Path $moduleRoot -Filter '*.ps*1' -Recurse |
        ForEach-Object { Invoke-ScriptAnalyzer -Path $_.FullName -Settings (Join-Path $PSScriptRoot 'PSScriptAnalyzerSettings.psd1') }
    if ($results) {
        $results | Format-Table RuleName, Severity, ScriptName, Line, Message -AutoSize -Wrap
        throw "PSScriptAnalyzer found $(@($results).Count) issue(s)."
    }
    Write-Host 'PSScriptAnalyzer: no issues' -ForegroundColor Green
}

function Invoke-Test {
    Import-Module Pester -MinimumVersion 5.5 -ErrorAction Stop
    # Tests assert how PSTask treats non-terminating errors, so don't let them be promoted
    $ErrorActionPreference = 'Continue'
    $config = New-PesterConfiguration
    $config.Run.Path = Join-Path $PSScriptRoot 'tests'
    $config.Run.Exit = $false
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Normal'
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = Join-Path $PSScriptRoot 'TestResults/testResults.xml'
    if ($Coverage) {
        $config.CodeCoverage.Enabled = $true
        $config.CodeCoverage.Path = $moduleRoot
        $config.CodeCoverage.OutputPath = Join-Path $PSScriptRoot 'coverage.xml'
        $config.CodeCoverage.OutputFormat = 'JaCoCo'
        $config.CodeCoverage.CoveragePercentTarget = 70
    }
    $result = Invoke-Pester -Configuration $config
    if ($result.FailedCount -gt 0) {
        throw "$($result.FailedCount) test(s) failed."
    }
}

switch ($Task) {
    'Analyze' { Invoke-Analyze }
    'Test'    { Invoke-Analyze; Invoke-Test }
    'Publish' {
        if (-not $NuGetApiKey) { throw 'Publish requires -NuGetApiKey.' }
        Invoke-Analyze
        Invoke-Test
        Publish-Module -Path $moduleRoot -NuGetApiKey $NuGetApiKey -Repository PSGallery
    }
}
