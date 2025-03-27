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

# Function to download the latest Ludusavi release
function Download-Ludusavi
{
	$releasesUrl = "https://api.github.com/repos/mtkennerly/ludusavi/releases/latest"
	$releaseInfo = Invoke-RestMethod -Uri $releasesUrl
	$asset = $releaseInfo.assets | Where-Object { $_.name -like "ludusavi-v*-win64.zip" }
	$downloadUrl = $asset.browser_download_url
	$latestVersion = $asset.name -replace "ludusavi-v([0-9.]+)-win64.zip", '$1'
	$output = "G:\Ludusavi\ludusavi-win64.zip"
	
	if (-not (Test-Path "G:\Ludusavi"))
	{
		New-Item -Path "G:\Ludusavi" -ItemType Directory
	}
	
	if (Test-Path "G:\Ludusavi\ludusavi.exe")
	{
		$currentVersion = & "G:\Ludusavi\ludusavi.exe" --version | ForEach-Object { $_ -replace "Ludusavi ([0-9.]+)", '$1' }
		if ($currentVersion -eq $latestVersion)
		{
			Write-Host "Ludusavi is already up to date (version $currentVersion)."
			return
		}
	}
	
	Invoke-WebRequest -Uri $downloadUrl -OutFile $output
	Expand-Archive -Path $output -DestinationPath "G:\Ludusavi" -Force
	Remove-Item $output
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
	Copy-Item -Path "G:\Ludusavi\ludusavi.exe" -Destination $driveLetter
	Start-Process -FilePath "G:\Ludusavi\ludusavi.exe" -ArgumentList "backup --path $ludusaviPath"
}

# Function to restore game saves
function Restore-GameSaves
{
	param ($driveLetter)
	$ludusaviPath = "$driveLetter\Ludusavi"
	if (Test-Path $ludusaviPath)
	{
		Start-Process -FilePath "G:\Ludusavi\ludusavi.exe" -ArgumentList "restore --path $ludusaviPath"
	}
	else
	{
		Write-Host "Could not find a Ludusavi folder on the USB drive. Please ensure $driveLetter\Ludusavi is present and contains backups."
	}
}

# Main script
if (-not (Test-Path "G:\Ludusavi\ludusavi.exe"))
{
	Download-Ludusavi
}

$driveLetter = Monitor-USB
$choice = Read-Host "USB drive detected at $driveLetter. Would you like to (B)ackup or (R)estore game saves?"

switch ($choice.ToUpper())
{
	"B" { Backup-GameSaves -driveLetter $driveLetter }
	"R" { Restore-GameSaves -driveLetter $driveLetter }
	default { Write-Host "Invalid choice. Please run the script again and choose either B or R." }
}
Start-Sleep 5