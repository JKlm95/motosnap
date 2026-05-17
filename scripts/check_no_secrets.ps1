# Staged-files-only secret scan (see check_no_secrets.sh). CI: -Full
param([switch]$Full)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$fail = $false
$isFull = $Full -or ($env:CHECK_NO_SECRETS_FULL -eq "1")
Write-Host "check_no_secrets: scanning (full=$isFull)..."

$guarded = @(
    "android/app/google-services.json",
    "lib/firebase_options.dart",
    "ios/Runner/GoogleService-Info.plist",
    "firebase.json"
)
$forbidden = @("motosnap-18101", "1008260666997", "5ded85270abdb2aa184a3c", "firebasestorage.app")
$allowedKeyFragments = @("AIzaSyDummyReplaceWithFlutterFireConfigure", "REPLACE_ME")

function Should-SkipPath([string]$path) {
    return $path -match '\.md$' -or $path -match 'check_no_secrets'
}

function Test-GuardedFile([string]$path) {
    if (-not (Test-Path $path)) { return }
    $content = Get-Content $path -Raw
    foreach ($m in $forbidden) {
        if ($content.Contains($m)) {
            Write-Host "ERROR: guarded file '$path' contains production marker: $m"
            $script:fail = $true
        }
    }
    if ($path -eq "firebase.json" -and $content -match '"flutter"') {
        Write-Host "ERROR: firebase.json must not contain a committed 'flutter' block."
        $script:fail = $true
    }
    Test-ApiKeysInFile $path
}

function Test-ApiKeysInFile([string]$path) {
    if ((Should-SkipPath $path) -or -not (Test-Path $path)) { return }
    Select-String -Path $path -Pattern 'AIzaSy[A-Za-z0-9_-]{20,}' | ForEach-Object {
        $line = $_.Line
        $ok = $false
        foreach ($frag in $allowedKeyFragments) {
            if ($line.Contains($frag)) { $ok = $true; break }
        }
        if (-not $ok) {
            Write-Host "ERROR: possible real Google API key in ${path}: $line"
            $script:fail = $true
        }
    }
}

if ($isFull) {
    foreach ($path in $guarded) { Test-GuardedFile $path }
    Get-ChildItem -Recurse -File -Include *.dart,*.json,*.plist,*.yaml,*.yml,*.kts |
        Where-Object { $_.FullName -notmatch '\\node_modules\\|\\build\\|\\.dart_tool\\' } |
        ForEach-Object { Test-ApiKeysInFile $_.FullName.Replace("$Root\", '').TrimStart('\') }
}
else {
    $changed = @(git diff --cached --name-only --diff-filter=ACM 2>$null) | Where-Object { $_ }
    if ($changed.Count -eq 0) {
        Write-Host "check_no_secrets: nothing staged — OK"
        exit 0
    }
    Write-Host "check_no_secrets: reviewing staged paths:"
    $changed | ForEach-Object { Write-Host "  $_" }
    foreach ($path in $changed) {
        if ($guarded -contains $path) { Test-GuardedFile $path }
        if ($path -match '\.(dart|json|plist|yaml|yml|kts)$') { Test-ApiKeysInFile $path }
    }
}

if ($fail) {
    Write-Host ""
    Write-Host "check_no_secrets FAILED — do not commit."
    exit 1
}
Write-Host "check_no_secrets: OK"
exit 0
