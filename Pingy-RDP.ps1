<#
.SYNOPSIS
    Exposes local RDP (port 3389) to the internet using Pinggy.
.DESCRIPTION
    Creates an SSH tunnel to Pinggy's free TCP gateway, enabling remote RDP access.
.NOTES
    - Run this script as Administrator to enable RDP and firewall rules.
    - This method requires no account or credit card.
#>

#Requires -RunAsAdministrator

# --- 1. Enable RDP and Firewall Rule ---
Write-Host "[1/3] Configuring RDP..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
Write-Host "RDP enabled and firewall rule added." -ForegroundColor Green

# --- 2. Create the Pinggy Tunnel ---
Write-Host "[2/3] Creating Pinggy tunnel to port 3389..." -ForegroundColor Cyan
Write-Host "You will be prompted to confirm the connection. Press 'y' to proceed." -ForegroundColor Yellow

# The key command to start the tunnel
ssh -p 443 -R0:127.0.0.1:3389 tcp@free.pinggy.io

# --- 3. (Script will pause while the tunnel is active) ---
Write-Host "[3/3] Tunnel closed. Exiting script."
