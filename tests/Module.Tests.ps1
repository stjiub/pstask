BeforeDiscovery {
    $script:moduleRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'PSTask'
    $script:publicNames = (Get-ChildItem (Join-Path $moduleRoot 'public') -Filter '*.ps1').BaseName
}

BeforeAll {
    . $PSScriptRoot/TestHelper.ps1
    $script:moduleRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'PSTask'
    Import-PSTaskForTest
}

Describe 'Module manifest' {
    BeforeAll {
        $script:manifest = Test-ModuleManifest -Path (Join-Path $moduleRoot 'PSTask.psd1')
    }

    It 'is valid' {
        $manifest | Should -Not -BeNullOrEmpty
    }

    It 'uses a semantic version' {
        $manifest.Version.ToString() | Should -Match '^\d+\.\d+\.\d+$'
    }

    It 'has no required modules that break PowerShell 7' {
        $manifest.RequiredModules | Should -BeNullOrEmpty
    }

    It 'declares project and license URIs' {
        $manifest.ProjectUri | Should -Not -BeNullOrEmpty
        $manifest.LicenseUri | Should -Not -BeNullOrEmpty
    }

    It 'exports exactly the files in public/' {
        $manifest.ExportedFunctions.Keys | Sort-Object | Should -Be ($publicNames | Sort-Object)
    }
}

Describe 'Module import' {
    It 'exports the public functions' {
        (Get-Command -Module PSTask).Name | Sort-Object | Should -Be ($publicNames | Sort-Object)
    }

    It 'does not export private functions' {
        Get-Command -Module PSTask -Name 'Format-ErrorForLog', 'Invoke-TextTask' -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'loads the main config' {
        InModuleScope PSTask { $script:Config.DefaultMode } | Should -Not -BeNullOrEmpty
    }

    It 'defines every status color and char the display code looks up' {
        InModuleScope PSTask {
            foreach ($status in 'Success', 'Warning', 'Failure', 'Default') {
                $script:Config.StatusColors[$status] | Should -Not -BeNullOrEmpty
                $script:Config.StatusChars[$status] | Should -Not -BeNullOrEmpty
            }
            $script:Config.TaskColor | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Help for <_>' -ForEach $publicNames {
    BeforeAll {
        $script:help = Get-Help $_ -Full
    }

    It 'has a synopsis' {
        $help.Synopsis.Trim() | Should -Not -BeNullOrEmpty
        $help.Synopsis | Should -Not -Match '^\s*\w+-\w+\s*$'
    }

    It 'has a description' {
        $help.Description | Should -Not -BeNullOrEmpty
    }

    It 'has at least one example' {
        @($help.Examples.Example).Count | Should -BeGreaterThan 0
    }
}
