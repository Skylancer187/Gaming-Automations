<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2025 v5.9.253
	 Created on:   	10/1/2025 2:32 PM
	 Created by:   	Matthew Nelson
	 Organization: 	Florida State University
	 Filename:     	Backup-MOSSAntiCheat.ps1
	===========================================================================
	.DESCRIPTION
		Recovers the MOSS Anti-Cheat files from the local host desk and copies
		them to an inserted USB Drive.
#>

# Define source paths
$sourceFolder = "C:\Users\Administrator\Desktop\MOSS"
$antiCheatInstaller = "C:\tools\install-mossanticheat.exe"

# Function to get removable drives
function Get-RemovableDrive
{
	Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
}

# Wait for a removable drive to be inserted
function Monitor-USB
{
    
    
	while ($true)
	{
	    $usbDrives = Get-Disk | Where-Object { $_.BusType -eq 'USB' }
        
		if ($usbDrives)
		{
			foreach ($drive in $usbDrives)
			{
				$driveLetter = ($drive | Get-Partition | Get-Volume).DriveLetter
				if ($driveLetter)
				{
					return $driveLetter
				}
			}
		}
		Write-Host "Please insert a USB drive..."
		Start-Sleep -Seconds 5
	}
}

# Use the first detected USB drive
$driveLetter = Monitor-USB
$usbDrive = "$driveLetter" + ":\"

# Ask user for confirmation
$confirmation = Read-Host "Copy your MOSS Data and Anti-Cheat Installer to the $usbDrive USB Drive? (Y/N)"
if ($confirmation -ne 'Y')
{
	Write-Host "Operation cancelled by user."
	Start-Sleep -Seconds 10
	exit
}

# Perform the copy
$destinationFolder = "$driveLetter\MOSS"
Write-Host "Copying MOSS data to $destinationFolder ..."
Copy-Item -Path "$sourceFolder" -Destination $usbDrive -Recurse -Force

Write-Host "Installing a Copy of Anti-Cheat Installer to $usbDrive ..."
Copy-Item -Path $antiCheatInstaller -Destination $usbDrive -Recurse -Force

Write-Host "Copy completed successfully."

Start-Sleep -Seconds 15
