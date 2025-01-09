# PSTask

## Create simple task:

```
New-PSTask -Name "Creating user account" -ScriptBlock { New-ADUser -Name "Chuck Norris" -SamAccountName "cnorris" }
```
-----

## Nesting tasks:
- You can nest as many PSTasks as you want inside other PSTasks.
- Tasks can go many layers deep
- If a PSTask calls a script or function inside it that also contains PSTasks, those tasks will become child tasks of the current PSTask
- Each nested layer will show the tasks as indented (when using Spinner output mode)
- Set indent maximum in the config file (defaults to a max of 4 indents before not indenting further)

```
New-PSTask -Name "Parent task" -ScriptBlock {
    New-PSTask -Name "Child Task 1" -ScriptBlock {
        Start-Sleep -Seconds 1
    }
    New-PSTask -Name "Child Task 2" -ScriptBlock {
        Start-Sleep -Seconds 2
    }
}
```
-----

## Set the visual mode:
- Available modes:
  - Spinner (default mode) - Shows a spinning indicator to visualize each task is running. If the task succeeds it will turn green with an '[OK]' in front of it. If it fails it will turn red with an 'X'.
  - Text - Shows each task name plainly without any spinners or progress indicators. Also does not show whether it succeeded or failed. Useful if having issues with Spinner mode.
  - Verbose - Shows each task name as a Write-Verbose message. Will not be visible unless -Verbose is used.
  - Silent - No console output whatsoever.
- All modes will log to file if logging is initialized.
- Spinner is the primary mode of the module, but other modes can be useful if running scripts non-interactively without the need to update the script to remove output messages

```
Set-PSTaskMode -Mode Slient
```
-----

## Set visibility level
- Available visibility levels:
  - Critical
  - Important
  - Normal
  - Verbose
  - Debug
- Normal is the default visibility level
- Only shows tasks in the output that match or are higher than the set visibility level
  
```
Set-PSTaskVisibilityLevel -VisibilityLevel Debug
```
-----

## Log PSTasks
- Initialize logging with `Start-PSTaskLogging` or just specify a LogName with `New-PSTask` to create a log file with a header
- Each subsequent PSTask will be logged under the currently initialized log file until the script ends (this includes nested PSTasks)
- Will prepend the date and time to the specified LogName
- If no LogPath is set then it will use the DefaultLogPath set in the module's config/main.psd1 file.
- PSTask should automatically clear the current log folder so a new task can be ran, but you can explicitly clear it and reset the logging state with `Stop-PSTaskLogging`
  
```
Start-PSTaskLogging -LogName "NewUserScript" -LogPath "C:\logs"
```
or
```
New-PSTask -Name "Initializing Logging" -LogName "NewUserScript" -LogPath "C:\logs" -ScriptBlock { }
```
Stop Logging
```
Stop-PSTaskLogging
```
