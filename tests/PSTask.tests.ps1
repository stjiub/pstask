beforeall {   
    $config = Import-PowerShellDataFile -Path "$(Split-Path -Parent $PSScriptRoot)\tools\config.psd1"
    $moduleName = $config.ModuleName
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $moduleRoot = "$projectRoot\$moduleName"
}

beforediscovery {
    $publicFunctions = (Get-ChildItem -Path "$moduleRoot\public\" -include '*.ps1' -recurse -ErrorAction SilentlyContinue).Basename
    $privateFunctions = (Get-ChildItem -Path "$moduleRoot\private\" -include '*.ps1' -recurse -ErrorAction SilentlyContinue).Basename
}

describe "Module Tests" {

    context "Module Setup" {

        it "has the root module <module>.psm1" {
            "$moduleRoot\$moduleName.psm1" | Should -Exist
        }

        it "has the manifest file of <module>.psd1" {
            "$moduleRoot\$moduleName.psd1" | Should -Exist
        }

        it "has public functions folder" {
            "$moduleRoot\public" | Should -Exist
        }

        it "has private functions folder" {
            "$moduleRoot\private" | Should -Exist
        }

        it "has configuration folder" {
            "$moduleRoot\config" | Should -Exist
        }

        it "has main.psd1 config file" {
            "$moduleRoot\config\main.psd1" | Should -Exist
        }

        it "<module> folder has private functions" {
            Get-ChildItem "$moduleRoot\private" -Recurse | Should -BeLike "*.ps1"
        }

        it "<module> is valid PowerShell code" {
            $psFile = Get-Content -Path "$moduleRoot\$moduleName.psm1" -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.Count | Should -Be 0
        }

        it "<module> manifest file uses semantic versioning (Major.Minor.Patch) " {
            $string = Select-String -Path $moduleRoot\$moduleName.psd1 -Pattern "ModuleVersion = " 
            $remove = $($string.Line).Replace($string.Pattern, "")
            $version = $remove.Replace("'", "")
            $version | Should -MatchExactly "\d+.\d+.\d+"
        }
    }

    context "Test Public Functions: <_>" -foreach $publicFunctions {

        beforeeach {
            $files = Get-ChildItem -Path "$moduleRoot\public" -Recurse
            foreach ($file in $files) {
                if ($file.Name -eq "$_.ps1") {
                    $parentFolder = $file.DirectoryName
                    break
                }
            }
        }

        it "<_>.ps1 should exist" {
            "$parentFolder\$_.ps1" | Should -Exist
        }

        it "<_>.ps1 and function name should match" {
            (Get-Content "$parentFolder\$_.ps1" | Select-String -Pattern "function $_").length | Should -HaveCount 1
        }

        it "<_> function name should contain '-'" {
            $_ | Should -BeLike "*-*"
        }

        it "<_> function name should use approved verb" {
            $split = $_ -split '-'
            (Get-Verb).Verb | Should -Contain $split[0]
        }

        it "<_> should have help block" {
            "$parentFolder\$_.ps1" | Should -FileContentMatch '<#'
            "$parentFolder\$_.ps1" | Should -FileContentMatch '#>'
        }

        it "<_> should have a SYNOPSIS section in help block" {
            "$parentFolder\$_.ps1" | Should -FileContentMatch '.SYNOPSIS'
        }

        it "<_> should have a DESCRIPTION section in the help block" {
            "$parentFolder\$_.ps1" | Should -FileContentMatch '.DESCRIPTION'
        }

        it "<_> should have a EXAMPLE section in the help block" {
            "$parentFolder\$_.ps1" | Should -FileContentMatch '.EXAMPLE'
        }

        it "<_> should be an advanced function" {
            "$parentFolder\$_.ps1" | Should -FileContentMatch 'function'
            "$parentFolder\$_.ps1" | Should -FileContentMatch 'cmdletbinding'
            "$parentFolder\$_.ps1" | Should -FileContentMatch 'param'
        }

        it "<_> should contain only one function" {
            (Get-Content "$parentFolder\$_.ps1" | Select-String -Pattern "function").length | Should -HaveCount 1
        }

        it "<_> should contain process block" {
            "$parentFolder\$_.ps1" | Should -FileContentMatch 'process {'
        }

        it "<_> should have opening braces on the same line as the statement" {
            $openingBracesExist = Get-Content "$parentFolder\$_.ps1" | Where-Object { $_.Trim() -eq '{' }
            if ($openingBracesExist) {
                Write-Warning "Found the following opening braces on their own line:"
                foreach ($openingBrace in $openingBracesExist) {
                    Write-Warning "Opening brace on its own line - $openingBrace"
                }
            }
            $openingBracesExist | Should -BeNullOrEmpty
        }

        it "<_> is valid PowerShell code" {
            $psFile = Get-Content -Path "$parentFolder\$_.ps1" -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }

    context "Test Private Functions: <_>" -foreach $privateFunctions {

        it "<_>.ps1 should exist" {
            "$moduleRoot\private\$_.ps1" | Should -Exist
        }

        it "<_>.ps1 and function name should match" {
            (Get-Content "$moduleRoot\private\$_.ps1" | Select-String -Pattern "function $_").length | Should -HaveCount 1
        }
    
        it "<_> should have a SYNOPSIS section in help block" {
            "$moduleRoot\private\$_.ps1" | Should -FileContentMatch '.SYNOPSIS'
        }
    
        it "<_> should have a DESCRIPTION section in the help block" {
            "$moduleRoot\private\$_.ps1" | Should -FileContentMatch '.DESCRIPTION'
        }
    
        it "<_> should be an advanced function" {
            "$moduleRoot\private\$_.ps1" | Should -FileContentMatch 'function'
            "$moduleRoot\private\$_.ps1" | Should -FileContentMatch 'cmdletbinding'
            "$moduleRoot\private\$_.ps1" | Should -FileContentMatch 'param'
        }
    
        it "<_> should contain only one function" {
            (Get-Content "$moduleRoot\private\$_.ps1" | Select-String -Pattern "function").length | Should -HaveCount 1
        }
    
        it "<_> should contain process block" {
            "$moduleRoot\private\$_.ps1" | Should -FileContentMatch 'process {'
        }

        it "<_> should have opening braces on the same line as the statement" {
            $openingBracesExist = Get-Content "$moduleRoot\private\$_.ps1" | Where-Object { $_.Trim() -eq '{' }
            if ($openingBracesExist) {
                Write-Warning "Found the following opening braces on their own line:"
                foreach ($openingBrace in $openingBracesExist) {
                    Write-Warning "Opening brace on its own line - $openingBrace"
                }
            }
            $openingBracesExist | Should -BeNullOrEmpty
        }
    
        it "<_> is valid PowerShell code" {
            $psFile = Get-Content -Path "$moduleRoot\private\$_.ps1" -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
    
}