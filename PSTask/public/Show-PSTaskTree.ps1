function Show-PSTaskTree {
    <#
    .SYNOPSIS
    Displays a tree visualization of completed tasks and their hierarchy.
    
    .DESCRIPTION
    Creates a visual representation of task execution, showing parent-child relationships,
    execution time, and status for all tasks that were run.
    
    .PARAMETER LogPath
    The path to the log file to analyze. If not specified, uses the current log if logging is active.
    
    .EXAMPLE
    Show-PSTaskTree
    
    Output example:
    Root Task [2.5s] ✓
    ├── Subtask 1 [1.2s] ✓
    │   ├── Nested Task A [0.3s] ✓
    │   └── Nested Task B [0.8s] ✓
    └── Subtask 2 [0.8s] ✗
        └── Nested Task C [0.8s] ✗
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$LogPath = $script:PSTaskLoggingState.LogPath
    )
    
    begin {
        # Tree drawing characters
        $chars = @{
            Corner = "└──"
            Branch = "├──"
            Vertical = "│  "
            Space = "   "
        }
    }
    
    process {
        if (-not $LogPath) {
            Write-Warning "No log file available to analyze"
            return
        }
        
        # Parse log file to build task tree
        $tasks = @{}
        $rootTasks = [System.Collections.ArrayList]::new()
        $currentNesting = 0
        $nestingStack = [System.Collections.Stack]::new()
        
        # Suppress output from ArrayList operations by assigning to $null
        $null = Get-Content $LogPath -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_ -match "\[(.*?)\] \[INFO\] TASK START - (.*)") {
                $timestamp = [datetime]::ParseExact($matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                $taskName = $matches[2]
                
                $task = @{
                    Name = $taskName
                    StartTime = $timestamp
                    EndTime = $null
                    Status = $null
                    Children = [System.Collections.ArrayList]@()
                    Nesting = $currentNesting
                    Parent = if ($nestingStack.Count -gt 0) { $nestingStack.Peek() } else { $null }
                }
                
                $tasks[$taskName] = $task
                
                if ($currentNesting -eq 0) {
                    $null = $rootTasks.Add($task)
                }
                elseif ($task.Parent) {
                    $null = $tasks[$task.Parent.Name].Children.Add($task)
                }
                
                $nestingStack.Push($task)
                $currentNesting++
            }
            elseif ($_ -match "\[(.*?)\] \[INFO\] TASK END - (.*) - (Success|Warning|Failure)") {
                $timestamp = [datetime]::ParseExact($matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                $taskName = $matches[2]
                $status = $matches[3]
                
                if ($tasks.ContainsKey($taskName)) {
                    $tasks[$taskName].EndTime = $timestamp
                    $tasks[$taskName].Status = $status
                    
                    if ($nestingStack.Count -gt 0 -and $nestingStack.Peek().Name -eq $taskName) {
                        $nestingStack.Pop()
                        $currentNesting--
                    }
                }
            }
        }
        
        # Helper function to print tree
        function Print-TaskNode {
            param($Task, $Prefix = "")
            
            $duration = $Task.EndTime - $Task.StartTime
            $statusSymbol = if ($script:Config.StatusChars.($Task.Status)) { $script:Config.StatusChars.($Task.Status) } else { $script:Config.StatusChars.Default }
            $statusColor = if ($script:Config.StatusColors.($Task.Status)) { $script:Config.StatusColors.($Task.Status) } else { $script:Config.StatusColors.Default }
            
            $line = "{0}{1} [{2:N1}s] {3}" -f $Prefix, $Task.Name, $duration.TotalSeconds, $statusSymbol
            Write-Host $line -ForegroundColor $statusColor
            
            for ($i = 0; $i -lt $Task.Children.Count; $i++) {
                $child = $Task.Children[$i]
                $isLast = ($i -eq $Task.Children.Count - 1)
                $newPrefix = $Prefix + $(if ($isLast) { $chars.Space } else { $chars.Vertical })
                $connector = if ($isLast) { $chars.Corner } else { $chars.Branch }
                Print-TaskNode -Task $child -Prefix ($newPrefix + $connector)
            }
        }
        
        # Print the tree
        $rootTasks | ForEach-Object {
            Print-TaskNode $_
        }
    }
}