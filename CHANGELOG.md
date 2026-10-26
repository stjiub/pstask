# Changelog

## 0.3.0

- Fix: Text mode failed because it read a color setting that did not exist
- Fix: the module could not be imported on PowerShell 7 because `ThreadJob` was listed as a required module; it is now loaded only on Windows PowerShell 5.1
- Fix: Spinner mode now falls back to Text mode when output is redirected (CI, scheduled tasks, pipelines)
- Fix: `Show-PSTaskTree` no longer indents root-level children and falls back to the last completed log
- Add: Pester test suite, GitHub Actions CI, and a `build.ps1` entry point
- Remove: internal build and deployment tooling

## 0.2.5

- Add Warning status for tasks with non-terminating errors
