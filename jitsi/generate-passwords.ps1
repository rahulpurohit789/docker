# PowerShell script to generate passwords for Jitsi Docker setup
# Run this in PowerShell: .\generate-passwords.ps1

# Function to generate random password
function Generate-Password {
    $bytes = New-Object byte[] 16
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    return [Convert]::ToHexString($bytes).ToLower()
}

Write-Host "Generating passwords for Jitsi Docker setup..." -ForegroundColor Green

# Generate passwords
$jvbPassword = Generate-Password
$jicofoPassword = Generate-Password
$jibriRecorderPassword = Generate-Password
$jibriXmppPassword = Generate-Password

Write-Host "`nGenerated Passwords:" -ForegroundColor Yellow
Write-Host "JVB_AUTH_PASSWORD=$jvbPassword"
Write-Host "JICOFO_AUTH_PASSWORD=$jicofoPassword"
Write-Host "JIBRI_RECORDER_PASSWORD=$jibriRecorderPassword"
Write-Host "JIBRI_XMPP_PASSWORD=$jibriXmppPassword"

# Check if .env file exists
if (Test-Path ".env") {
    Write-Host "`nUpdating .env file..." -ForegroundColor Green
    
    # Read current .env file
    $envContent = Get-Content ".env" -Raw
    
    # Replace or add passwords
    $envContent = $envContent -replace "JVB_AUTH_PASSWORD=.*", "JVB_AUTH_PASSWORD=$jvbPassword"
    $envContent = $envContent -replace "JICOFO_AUTH_PASSWORD=.*", "JICOFO_AUTH_PASSWORD=$jicofoPassword"
    $envContent = $envContent -replace "JIBRI_RECORDER_PASSWORD=.*", "JIBRI_RECORDER_PASSWORD=$jibriRecorderPassword"
    $envContent = $envContent -replace "JIBRI_XMPP_PASSWORD=.*", "JIBRI_XMPP_PASSWORD=$jibriXmppPassword"
    
    # If passwords don't exist, add them
    if ($envContent -notmatch "JVB_AUTH_PASSWORD=") {
        $envContent += "`nJVB_AUTH_PASSWORD=$jvbPassword"
    }
    if ($envContent -notmatch "JICOFO_AUTH_PASSWORD=") {
        $envContent += "`nJICOFO_AUTH_PASSWORD=$jicofoPassword"
    }
    if ($envContent -notmatch "JIBRI_RECORDER_PASSWORD=") {
        $envContent += "`nJIBRI_RECORDER_PASSWORD=$jibriRecorderPassword"
    }
    if ($envContent -notmatch "JIBRI_XMPP_PASSWORD=") {
        $envContent += "`nJIBRI_XMPP_PASSWORD=$jibriXmppPassword"
    }
    
    # Write back to file
    Set-Content -Path ".env" -Value $envContent -NoNewline
    
    Write-Host "Passwords saved to .env file!" -ForegroundColor Green
} else {
    Write-Host "`nWarning: .env file not found!" -ForegroundColor Red
    Write-Host "Please create .env file first, then run this script again." -ForegroundColor Yellow
    Write-Host "`nCopy the passwords above and add them to your .env file manually." -ForegroundColor Yellow
}

Write-Host "`nDone!" -ForegroundColor Green

