<#
.SYNOPSIS
    強健版 ADB 專用執行腳本，支援原樣轉送任意參數。
.DESCRIPTION
    自動尋找 SDK 中的 adb.exe，檢查裝置連線狀態，並執行傳入的 adb 指令。
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AdbArgs
)

# 略過 -s／-t／-H／-P／-L 與它們的值，回傳第一個非選項參數（也就是 adb 子命令）
function Get-AdbSubcommand($Tokens) {
    $valueTaking = @("-s", "-t", "-H", "-P", "-L")
    for ($i = 0; $i -lt $Tokens.Count; $i++) {
        if ($valueTaking -contains $Tokens[$i]) { $i++; continue }
        if ($Tokens[$i].StartsWith("-")) { continue }
        return $Tokens[$i]
    }
    return ""
}

# 只認「序號 + 空白 + device」的行，避免 unauthorized／offline／daemon 訊息被誤判成可用裝置
function Get-ActiveDevices($Lines) {
    return @($Lines | Select-String -Pattern '^\S+\s+device\s*$')
}

# 1. 自動偵測 ADB 路徑（優先指定路徑，其次抓環境變數）
$defaultPath = "E:\Android\Sdk\platform-tools\adb.exe"
$adbPath = $null

if (Test-Path $defaultPath) {
    $adbPath = $defaultPath
} else {
    # 嘗試從環境變數或 PATH 中尋找
    $envAdb = Get-Command adb -ErrorAction SilentlyContinue
    if ($envAdb) {
        $adbPath = $envAdb.Source
    }
}

if (-not $adbPath) {
    [Console]::Error.WriteLine("[-] 找不到 ADB 執行檔！請確認 Android SDK 路徑是否正確。")
    exit 1
}

# 2. 檢查是否有裝置連線（只有少數不需要裝置的子命令會跳過）
$devicesOutput = & $adbPath devices
if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine("[-] adb devices 執行失敗（離開碼: $LASTEXITCODE）")
    exit 1
}
$activeDevices = @(Get-ActiveDevices $devicesOutput)

# 不需要裝置的子命令白名單；其餘一律視為需要裝置（logcat／am／uninstall／reboot 都算）
$noDeviceCommands = @("", "devices", "version", "start-server", "kill-server", "connect", "disconnect", "pair", "mdns", "keygen", "help", "wait-for-device")
$subcommand = Get-AdbSubcommand $AdbArgs

if ($noDeviceCommands -notcontains $subcommand -and $activeDevices.Count -eq 0) {
    [Console]::Error.WriteLine("[!] 目前沒有偵測到已授權且線上（Device）的 Android 裝置或模擬器。")
    [Console]::Error.WriteLine(($devicesOutput -join [Environment]::NewLine))
    exit 1
}

# 3. 執行目標 ADB 指令並原樣轉送參數
# 這裡使用 & 符號呼叫執行檔，並將剩餘參數直接展開
& $adbPath @AdbArgs
$exitCode = $LASTEXITCODE

# 4. 錯誤處理提示
if ($exitCode -ne 0) {
    [Console]::Error.WriteLine("[-] ADB 指令執行失敗，離開碼: $exitCode")
}

exit $exitCode