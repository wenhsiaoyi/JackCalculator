<#
.SYNOPSIS
    量一個 Android process 在一段時間內吃掉多少 CPU（以「單一核心的百分比」表示）。

.EXAMPLE
    ./scripts/measure_cpu.ps1 -Package wenhsiaoyi.jack_calculator -Seconds 30
#>
param(
    [Parameter(Mandatory = $true)][string]$Package,
    [int]$Seconds = 30
)

$adbScript = Join-Path $PSScriptRoot "adb_monitor.ps1"

# pidof 在多行程 App 會回多個 pid（以空白分隔）；只量第一個，否則會拼出 "/proc/1234 5678/stat"
$pidText = (& $adbScript shell pidof $Package | Out-String).Trim()
$processId = ($pidText -split '\s+')[0]
if ($LASTEXITCODE -ne 0 -or -not $processId) {
    [Console]::Error.WriteLine("$Package 沒有在執行（或 adb 失敗，exit=$LASTEXITCODE）")
    exit 1
}

function Read-CpuTicks($targetPid) {
    # /proc/<pid>/stat 的第 14、15 欄是 utime、stime（單位：時鐘 tick，通常 100 Hz）
    # 第 2 欄 comm 可能含空白（例如 "(my app)"），先切掉 "pid (comm) " 前綴再分欄，
    # 切完 utime/stime 就落在索引 11、12
    $raw = (& $adbScript shell cat /proc/$targetPid/stat | Out-String).Trim()
    if (-not $raw) {
        [Console]::Error.WriteLine("讀不到 /proc/$targetPid/stat")
        exit 1
    }
    $fields = ($raw -replace '^[^)]*\)\s*', '') -split '\s+'
    return [long]$fields[11] + [long]$fields[12]
}

$before = Read-CpuTicks $processId
Start-Sleep -Seconds $Seconds
$after = Read-CpuTicks $processId

$ticks = $after - $before
# 100 ticks = 1 秒的單核 CPU
$percent = [math]::Round($ticks / $Seconds, 1)
"pid=$processId  $ticks ticks / ${Seconds}s  =>  $percent % of one core"
