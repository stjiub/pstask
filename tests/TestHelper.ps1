function Import-PSTaskForTest {
    $manifest = Join-Path (Split-Path -Parent $PSScriptRoot) 'PSTask/PSTask.psd1'
    Import-Module $manifest -Force
}

function Reset-PSTaskState {
    InModuleScope PSTask {
        $script:PSTaskLoggingState = @{ IsLogging = $false; LogPath = $null; LastLogPath = $null; ReferenceCount = 0 }
        $script:PSTaskNestingLevel = 0
        $script:PSTaskStopOnFailure = $false
        $script:PSTaskDebugMode = $false
        $script:PSTaskMode = 'Text'
        $script:PSTaskVisibilityLevel = 'Normal'
    }
}
