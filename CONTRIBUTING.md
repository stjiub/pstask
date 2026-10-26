# Contributing

1. Fork and branch from `master`.
2. Make your change and add or update tests in `tests/`.
3. Run `./build.ps1 -Task Test` and make sure it passes.
4. Open a pull request describing what changed and why.

## Layout

```
PSTask/public/    exported commands, one function per file named after the command
PSTask/private/   internal helpers, not exported
PSTask/config/    default settings (main.psd1)
PSTask/class/     C# helper used to draw the spinner
tests/            Pester 5 tests
build.ps1         analyze, test and publish entry point
```

New public commands need comment-based help (synopsis, description and an example); the test suite checks for it.

## Style

- Four-space indentation. PowerShell, C# and manifest files are checked out with CRLF line endings (see `.gitattributes`).
- Keep `PSScriptAnalyzerSettings.psd1` exclusions to a minimum and explain any new one.
- Commit messages are one line in the form `area: what changed`.
