properties {
    $config = Import-PowerShellDataFile -Path "$PSScriptRoot\config.psd1"
    $moduleName = $config.ModuleName
    $repoName = $config.RepoName
    $tempDir = "$env:TEMP\$moduleName"

    $projectRoot = Split-Path -Parent $PSScriptRoot
    $moduleRoot = "$projectRoot\$moduleName"
    
    $public  = @(Get-ChildItem -Path "$moduleRoot\public\" -include '*.ps1' -recurse -ErrorAction SilentlyContinue)
    $private = @(Get-ChildItem -Path "$moduleRoot\private\" -include '*.ps1' -recurse -ErrorAction SilentlyContinue)
}


task default -depends Analyze

    task Analyze {
        $exclude = @("PSUseApprovedVerbs",
                     "PSAvoidUsingConvertToSecureStringWithPlainText",
                     "PSAvoidDefaultValueSwitchParameter",
                     "PSUseSingularNouns",
                     "PSAvoidUsingUsernameAndPasswordParams"
        )
        foreach ($function in $public) {
            $saResults = Invoke-ScriptAnalyzer -Path $function -ExcludeRule $exclude  -Severity @('Error') -Recurse -Verbose:$false
            if ($saResults) {
                $saResults | Format-Table  
                Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'        
            }
        }
    }

    task Test {
        $testResults = Invoke-Pester -Path "$projectRoot\tests" -PassThru
        if ($testResults.FailedCount -gt 0) {
            $testResults | Format-List
            Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
        }
    }

    task Manifest -depends Analyze, Test {
        try {
            # Get current module version from manifest
            $manifestPath = "$moduleRoot\$moduleName.psd1"
            $manifest = Test-ModuleManifest -Path $manifestPath
            [version]$version = $manifest.Version
            Write-Output "Old Version: $version"
    
            # Increment build number
            [int]$build = $version.Build + 1
            [version]$script:newVersion = New-Object -TypeName System.Version -ArgumentList ($version.Major, $version.Minor, $build)
            Write-Output "New Version: $script:newVersion"
    
            $public  = @(Get-ChildItem -Path "$moduleRoot\public\" -include '*.ps1' -Recurse -ErrorAction SilentlyContinue).Basename
    
            # Update manifest
            Update-ModuleManifest -Path $manifestPath -ModuleVersion $script:newVersion -FunctionsToExport $public
        }
        catch {
            throw $_
        }
    }

    task Commit {
        # Publish the new version back to remote git repo
        try {
            $env:Path += ";$env:ProgramFiles\Git\cmd"
            Import-Module posh-git -ErrorAction Stop
            git checkout main
            git add --all
            git status

            git commit -s -m "$($script:newVersion.ToString())"
            git push origin main
            Write-Host "$moduleName PowerShell Module pushed to remote repo." -ForegroundColor Cyan
        }
        catch {
            Write-Warning "Pushing commit to remote repo failed."
            throw $_
        }
    }

    task Publish -depends Analyze, Test, Manifest, Commit {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
        Copy-Item -Path $moduleRoot -Destination $tempDir -Recurse

        $cert = @(Get-ChildItem cert:\CurrentUser\My -codesigning)[0]
        $filesToSign = @(Get-ChildItem -Path $tempDir -include '*.ps1','*.psm1','*.psd1' -Recurse -ErrorAction SilentlyContinue)
        $filesToSign | foreach-object {
            Set-AuthenticodeSignature $PSItem.fullname $cert
        }

        Publish-Module -Path $tempDir -Repository $repoName
        Remove-Item -Path $tempDir -Recurse -Force
        Update-Module -Name $moduleName
    }

    task Update {
        Update-Module -Name $moduleName
    }