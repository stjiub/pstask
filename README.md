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
  - Spinner (default mode)
  - Text
  - Verbose
  - Silent
- 
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
- Initialize logging with `Start-PSTaskLogger` or just specify a LogName with `New-PSTask` to create a log file with a header
- Each subsequent PSTask will be logged under the currently initialized log file until the script ends (this includes nested PSTasks)
- Will prepend the date and time to the specified LogName
- If no LogPath is set then it will use the DefaultLogPath set in the module's config/main.psd1 file.
- PSTask should automatically clear the current log folder so a new task can be ran, but you can explicitly clear it and reset the logging state with `Stop-PSTaskLogging`
  
```
Start-PSTaskLogger -LogName "NewUserScript" -LogPath "C:\logs"
```
or
```
New-PSTask -Name "Initializing Logging" -LogName "NewUserScript" -LogPath "C:\logs" -ScriptBlock { }
```
-----

## Generate a report from the log
- Output the report either as an object or in a console readable way.
```
Get-PSTaskReport -LogFilePath "C:\logs\NewUserScript.log" -Format "Console"
```