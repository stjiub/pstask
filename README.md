# PSTask

[![CI](https://github.com/stjiub/pstask/actions/workflows/ci.yml/badge.svg)](https://github.com/stjiub/pstask/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Run PowerShell script blocks as named **tasks**. PSTask shows a live spinner while each task runs, turns it into a pass/warn/fail line when it finishes, supports nested tasks, and writes a structured log you can read back later.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+ on Windows
- Windows PowerShell 5.1 also needs the [`ThreadJob`](https://www.powershellgallery.com/packages/ThreadJob) module (built in to PowerShell 7)

## Install

```powershell
Install-Module PSTask -Scope CurrentUser
```

Or clone this repository and import the manifest directly:

```powershell
Import-Module ./PSTask/PSTask.psd1
```

## Quick start

```powershell
New-PSTask -Name "Creating user account" -ScriptBlock {
    New-ADUser -Name "Chuck Norris" -SamAccountName "cnorris"
}
```

### Task status

| Status | Meaning |
| --- | --- |
| `[OK]` | The script block finished without errors |
| `[!]` | The script block finished but wrote non-terminating errors |
| `[X]` | The script block threw a terminating error |

A failed task does not stop your script by default. Add `-StopOnFailure` to rethrow after the failure is displayed. The failure then cascades: every parent task also stops, and tasks nested inside a `-StopOnFailure` parent inherit it.

```powershell
New-PSTask -Name "Deploy" -StopOnFailure -ScriptBlock {
    New-PSTask -Name "Build"  -ScriptBlock { ... }
    New-PSTask -Name "Upload" -ScriptBlock { ... }   # skipped if Build fails
}
```

### Nested tasks

Tasks can be nested to any depth. A task started inside a script or function called from another task becomes a child of that task. Spinner mode indents each level (up to `MaxIndentationLevel` in `config/main.psd1`, default 4).

```powershell
New-PSTask -Name "Parent task" -ScriptBlock {
    New-PSTask -Name "Child task 1" -ScriptBlock { Start-Sleep -Seconds 1 }
    New-PSTask -Name "Child task 2" -ScriptBlock { Start-Sleep -Seconds 2 }
}
```

## Output modes

| Mode | Behavior |
| --- | --- |
| `Spinner` | Animated spinner that resolves to a status. Default. Falls back to `Text` when output is redirected |
| `Text` | Plain task name, output and a final status line. No cursor movement |
| `Normal` | No decoration. Output and errors flow to the pipeline and error stream as usual |
| `Silent` | No console output |

All modes write to the log when logging is active.

```powershell
New-PSTask -Name "Quiet one" -Mode Silent -ScriptBlock { ... }   # one task
Set-PSTaskMode -Mode Text                                         # rest of the session
```

Set the default for every session with `DefaultMode` in `PSTask/config/main.psd1`.

### Visibility levels

Each task has a visibility level (`Debug`, `Verbose`, `Normal`, `Important`, `Critical`; default `Normal`). Tasks below the session threshold still run and still log, but they run silently.

```powershell
Set-PSTaskVisibilityLevel -Level Important
New-PSTask -Name "Noisy detail" -VisibilityLevel Verbose  -ScriptBlock { ... }   # hidden
New-PSTask -Name "Key step"     -VisibilityLevel Critical -ScriptBlock { ... }   # shown
```

### Debugging

`Set-PSTaskDebug -Enabled` forces every task to `Normal` mode so `Write-Verbose`, `Write-Debug` and friends reach your console while you troubleshoot. `Set-PSTaskDebug -Disabled` restores normal behavior.

## Logging

Start logging explicitly, or pass `-LogName` to the first `New-PSTask`. Every task, nested or not, is recorded in one file until logging stops.

```powershell
Start-PSTaskLogging -LogName "NewUserScript" -LogPath "C:\logs"
# ... New-PSTask calls ...
Stop-PSTaskLogging
```

```powershell
New-PSTask -Name "Step one" -LogName "NewUserScript" -LogPath "C:\logs" -ScriptBlock { ... }
```

- The file is named `<date>-<LogName>.log`. Use `-LogPathOverride` on `Start-PSTaskLogging` to choose the exact file instead.
- If no `-LogPath` is given, the log goes to `Logging.DefaultLogPath` in `config/main.psd1`, or the current directory when that is unset.
- The header records the user, machine, host and PowerShell version. Add your own fields with `-CustomFields @{ Environment = "Prod" }`.
- Add your own lines from inside a task with `Write-PSTaskLog "message" -Level WARNING`.

### Reading logs

```powershell
Show-PSTaskLog                  # active log, or the last completed one, color-coded
Show-PSTaskLog -Level ERROR     # errors only
Show-PSTaskLog -Tail 20
Show-PSTaskTree                 # task hierarchy with durations and status
```

```
Provision workstation [1.0s] [OK]
├──Create local account [0.0s] [OK]
├──Install software [1.0s] [!]
└──Join domain [0.0s] [X]
```

Durations in the tree come from log timestamps, which have one-second resolution. Task names are used as keys, so give sibling tasks distinct names.

## Demo

`examples/Demo.ps1` runs a harmless provisioning script with nested tasks, a warning, a failure and a `-StopOnFailure` cascade, then prints the task tree. Run it in an interactive console to see the spinner:

```powershell
./examples/Demo.ps1
```

## Commands

| Command | Purpose |
| --- | --- |
| `New-PSTask` | Run a script block as a task |
| `Set-PSTaskMode` | Set the session default output mode |
| `Set-PSTaskVisibilityLevel` | Set the session visibility threshold |
| `Set-PSTaskDebug` | Force `Normal` mode while debugging |
| `Start-PSTaskLogging` / `Stop-PSTaskLogging` | Begin and end a log file |
| `Write-PSTaskLog` | Add a custom entry to the active log |
| `Show-PSTaskLog` | Display a log with color-coding |
| `Show-PSTaskTree` | Display a log as a task tree |

Use `Get-Help <command> -Full` for parameters and examples.

## Development

```powershell
Install-Module Pester -MinimumVersion 5.5, PSScriptAnalyzer -Scope CurrentUser
./build.ps1 -Task Test              # PSScriptAnalyzer + Pester
./build.ps1 -Task Test -Coverage    # also writes coverage.xml
```

The live-cursor Spinner code needs an interactive console and is not covered by the automated tests. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
