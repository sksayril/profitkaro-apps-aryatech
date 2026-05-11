# Starts the Android emulator if none is connected, waits until it is ready, then runs the Flutter app.
# Usage: .\scripts\run-android.ps1
#        .\scripts\run-android.ps1 -EmulatorId Pixel_9_Pro_XL_API_35
# Extra args are passed to flutter run, e.g. .\scripts\run-android.ps1 --profile

param(
  [string]$EmulatorId = "Pixel_9_Pro_API_35"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Test-FlutterEmulatorConnected {
  $out = & flutter devices 2>&1 | Out-String
  return $out -match "emulator-\d+"
}

function Wait-AdbBoot {
  $adb = Get-Command adb -ErrorAction SilentlyContinue
  if (-not $adb) {
    Write-Error "adb was not found in PATH. Add Android SDK platform-tools to PATH (same as for Flutter/Android Studio)."
  }
  Write-Host "Waiting for Android device..."
  & adb wait-for-device | Out-Null
  $deadline = (Get-Date).AddMinutes(4)
  do {
    $boot = (& adb shell getprop sys.boot_completed 2>$null).Trim()
    if ($boot -eq "1") { return }
    Start-Sleep -Seconds 2
  } while ((Get-Date) -lt $deadline)
  Write-Warning "Boot completion not confirmed in time; continuing with flutter run."
}

if (-not (Test-FlutterEmulatorConnected)) {
  Write-Host "Launching emulator: $EmulatorId"
  & flutter emulators --launch $EmulatorId
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "flutter emulators --launch exited with $LASTEXITCODE (emulator may already be starting). Waiting for device..."
  }
} else {
  Write-Host "An Android emulator is already connected; skipping launch."
}

Wait-AdbBoot
Write-Host "Running: flutter run $args"
& flutter run @args
