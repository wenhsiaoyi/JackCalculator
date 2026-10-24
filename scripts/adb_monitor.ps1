$adb = "E:\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    [Console]::Error.WriteLine("adb not found: $adb")
    exit 1
}

& $adb @args
# Propagate adb's exit code so callers can tell success from failure (AGENTS.md rule 2).
# NOTE: this file stays ASCII-only on purpose -- it has no BOM, and PowerShell 5.1 reads
# BOM-less .ps1 as CP950, which mangles any Chinese text.
exit $LASTEXITCODE
