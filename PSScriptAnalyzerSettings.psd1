@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # The module draws a console UI; Write-Host is intentional
        'PSAvoidUsingWriteHost'
        # Session-state setters and task runners are not worth -WhatIf/-Confirm plumbing
        'PSUseShouldProcessForStateChangingFunctions'
        # False positives: variables set inside ForEach-Object or passed to a thread job via param()
        'PSUseDeclaredVarsMoreThanAssignments'
        'PSUseUsingScopeModifierInNewRunspaces'
    )
}
