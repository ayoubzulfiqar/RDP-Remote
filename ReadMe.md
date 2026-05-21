Set-ExecutionPolicy RemoteSigned -Scope Process   # allow script execution
.\Start-RdpTunnel.ps1


powershell.exe -ExecutionPolicy Bypass -File "./Start-RdpTunnel.ps1"

Set-ExecutionPolicy Bypass -Scope Process
Set-ExecutionPolicy Unrestricted
