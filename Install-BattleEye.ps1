$DestinyBattlEyePath = "G:\Launchers\steamapps\common\Destiny 2\battleye\BEService_x64.exe"

# Install BattlEye silently
Start-Process -FilePath $DestinyBattlEyePath -Wait -NoNewWindow

Write-Host "BattlEye installation for Destiny 2 completed successfully."

# Wait 15 seconds before launching the game
Start-Sleep -Seconds 15

# Launch Destiny 2 from Steam
Start-Process -FilePath "steam://rungameid/1085660"

Write-Host "Destiny 2 launched successfully."

Start-Sleep -Seconds 15