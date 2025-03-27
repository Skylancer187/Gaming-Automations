<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2025 v5.9.253
	 Created on:   	3/4/2025 9:35 AM
	 Created by:   	Matthew Nelson
	 Organization: 	Florida State University
	 Filename:     	Ludusavi-BackupRestore.ps1
	===========================================================================
	.DESCRIPTION
		Quick Ludusavi CLI to backup and restore game saves to a USB Drive.
#>

# Configurations
$cafeName = "Garnet Gaming Lounge"
$sleepTime = "30"

# Function to download the latest Ludusavi release
function Download-Ludusavi
{
	$releasesUrl = "https://api.github.com/repos/mtkennerly/ludusavi/releases/latest"
	$releaseInfo = Invoke-RestMethod -Uri $releasesUrl
	$asset = $releaseInfo.assets | Where-Object { $_.name -like "ludusavi-v*-win64.zip" }
	$downloadUrl = $asset.browser_download_url
	$latestVersion = $asset.name -replace "ludusavi-v([0-9.]+)-win64.zip", '$1'
	$output = "C:\Ludusavi\ludusavi-win64.zip"
	
	if (-not (Test-Path "C:\Ludusavi"))
	{
		New-Item -Path "C:\Ludusavi" -ItemType Directory
	}
	
	Invoke-WebRequest -Uri $downloadUrl -OutFile $output
	Expand-Archive -Path $output -DestinationPath "C:\Ludusavi" -Force
	Remove-Item $output
}

# Function to find Ludusavi executable
function Find-Ludusavi
{
	$drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
	foreach ($drive in $drives)
	{
		$ludusaviPath = "$drive\Ludusavi\ludusavi.exe"
		if (Test-Path $ludusaviPath)
		{
			return $ludusaviPath
		}
	}
	return $null
}

# Function to monitor for USB drive insertion
function Monitor-USB
{
	while ($true)
	{
		$drives = Get-WmiObject -Query "SELECT * FROM Win32_Volume WHERE DriveType = 2"
		if ($drives)
		{
			foreach ($drive in $drives)
			{
				$driveLetter = $drive.DriveLetter
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

# Function to backup game saves
function Backup-GameSaves
{
	param ($driveLetter)
	$ludusaviPath = "$driveLetter\Ludusavi"
	if (-not (Test-Path $ludusaviPath))
	{
		New-Item -Path $ludusaviPath -ItemType Directory
	}
	Copy-Item -Path "C:\Ludusavi\ludusavi.exe" -Destination $driveLetter
	Start-Process -FilePath "C:\Ludusavi\ludusavi.exe" -ArgumentList "backup --path $ludusaviPath"
}

# Function to restore game saves
function Restore-GameSaves
{
	param ($driveLetter)
	$ludusaviPath = "$driveLetter\Ludusavi"
	if (Test-Path $ludusaviPath)
	{
		Start-Process -FilePath "C:\Ludusavi\ludusavi.exe" -ArgumentList "restore --path $ludusaviPath"
	}
	else
	{
		Write-Host "Could not find a Ludusavi folder on the USB drive. Please ensure $driveLetter\Ludusavi is present and contains backups."
	}
}

# Main script
$ludusaviExe = Find-Ludusavi
if (-not $ludusaviExe)
{
	Download-Ludusavi
	$ludusaviExe = "C:\Ludusavi\ludusavi.exe"
}

$driveLetter = Monitor-USB
$choice = Read-Host "`nUSB drive detected at $driveLetter. Would you like to (B)ackup or (R)estore game saves?"

switch ($choice.ToUpper())
{
	"B" { Backup-GameSaves -driveLetter $driveLetter }
	"R" { Restore-GameSaves -driveLetter $driveLetter }
	default { Write-Host "Invalid choice. Please run the script again and choose either B or R." }
}

Write-Host "`n`nLudusavi will execute in another window, please enter y/n to complete the backup/restore.`n`nAfter it's done, a copy of the current Ludusavi will be placed on your USB drive`nand you can execute it on another computer to backup/restore your saves.`nYou can backup your saves and bring them to $cafeName by running the tool to backup on your computer`nand restore at $cafeName computers."

Write-Host "`n`nThanks for using our free tool, but we accept no responsiblities with lost or corrupt data.`nThis is a tool for use as a benefits to our guests."

Start-Sleep -Seconds $sleepTime