<#
.SYNOPSIS
    Exposes local RDP (port 3389) to the internet using ngrok.
.DESCRIPTION
    Downloads ngrok (if missing), starts a TCP tunnel to port 3389, and displays
    the public address to use with Remote Desktop Connection.
.NOTES
    - Run as Administrator to check/enable RDP and firewall rules.
    - Requires a free ngrok account (get authtoken at https://dashboard.ngrok.com/auth).
#>

#Requires -RunAsAdministrator

$ngrokDir = "$env:USERPROFILE\.ngrok2"
$ngrokExe = "$ngrokDir\ngrok.exe"
$ngrokUrl = "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip"
$zipFile = "$env:TEMP\ngrok.zip"

# 1. Enable RDP if not already enabled
Write-Host "Checking Remote Desktop status..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
Write-Host "RDP enabled and firewall rule added." -ForegroundColor Green

# 2. Ensure ngrok is present
if (-not (Test-Path $ngrokExe)) {
    Write-Host "ngrok not found. Downloading..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $ngrokUrl -OutFile $zipFile
    Expand-Archive -Path $zipFile -DestinationPath $ngrokDir -Force
    Remove-Item $zipFile
    Write-Host "ngrok downloaded to $ngrokDir" -ForegroundColor Green
}

# 3. Ask for ngrok authtoken (only needed once)
$authToken = $null
if (Test-Path "$ngrokDir\ngrok.yml") {
    $config = Get-Content "$ngrokDir\ngrok.yml" -Raw
    if ($config -match "authtoken:\s*(\S+)") { $authToken = $Matches[1] }
}
if (-not $authToken) {
    Write-Host "`nYou need an ngrok account (free). Sign up at: https://dashboard.ngrok.com/signup" -ForegroundColor Cyan
    $authToken = Read-Host "Paste your ngrok authtoken"
    & $ngrokExe config add-authtoken $authToken
}

# 4. Start ngrok TCP tunnel to port 3389
Write-Host "Starting ngrok tunnel to localhost:3389 ..." -ForegroundColor Cyan
$ngrokLog = "$env:TEMP\ngrok.log"
Start-Process -NoNewWindow -FilePath $ngrokExe -ArgumentList "tcp 3389 --log=$ngrokLog" -PassThru

# 5. Wait for tunnel to be ready and extract the public address
Start-Sleep -Seconds 3
$retries = 0
$publicAddr = $null
while ($retries -lt 10 -and -not $publicAddr) {
    $log = Get-Content $ngrokLog -ErrorAction SilentlyContinue
    if ($log -match 'started tunnel.*url=(tcp://\S+)') {
        $publicAddr = $Matches[1] -replace 'tcp://',''
        break
    }
    Start-Sleep -Seconds 2
    $retries++
}

if ($publicAddr) {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "✅ RDP tunnel is ACTIVE" -ForegroundColor Green
    Write-Host "Connect using Remote Desktop Client:" -ForegroundColor White
    Write-Host "   mstsc /v:$publicAddr" -ForegroundColor Yellow
    Write-Host "Or use the address: $publicAddr" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "`nKeep this window open. Press Ctrl+C to stop the tunnel." -ForegroundColor Cyan
} else {
    Write-Host "❌ Failed to get tunnel address. Check ngrok logs: $ngrokLog" -ForegroundColor Red
}

# 6. Keep script alive
Wait-Event
