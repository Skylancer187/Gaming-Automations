<#
	.NOTES
	===========================================================================
	 Created with:	SAPIEN Technologies, Inc., PowerShell Studio 2025 v5.9.253
	 Created on:	9/15/2025 3:02 PM
	 Created by:	Matthew Nelson
	 Organization:	Florida State University
	 Filename:	Install-MOSSAntiCheat.ps1
	===========================================================================
	.DESCRIPTION
		Downloads, Installs, and Executes the MOSS Application for Esports Titles
#>

# Check for admin rights
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	Write-Warning "Please run this script as Administrator."
	Pause
	exit
}

function Wait-ForMOSSAndOpenDesktop
{
	$processName = "$processWatch" # MOSS.exe is the typical name, but just "MOSS" works for Get-Process
	Write-Host "Waiting for MOSS AntiCheat to exit..."
	
	# Wait while MOSS is running
	while (Get-Process -Name $processName -ErrorAction SilentlyContinue)
	{
		Start-Sleep -Seconds 5
	}
	
	Write-Host "MOSS has exited. Opening Desktop..."
	Start-Process explorer.exe "$env:USERPROFILE\Desktop"
	
	Write-Host "`n`nPlease copy your required files to be submitted to Esports or Staff Admins.`nRestarting this computer will remove these files from the host and will not be recoverable."
	Start-Sleep 30
}

# Variables
$downloadUrl = "https://nohope.eu/down/MossX645.zip" # This may require updates often. https://nohope.eu
$destinationPath = "$env:USERPROFILE\Downloads\Moss.zip"
$extractPath = "$env:USERPROFILE\MOSS"
$password = "Moss"
$gameCodeFile = "$extractPath\MOSSGameCodes.txt" # Ensure this file exists in the same folder as the script
$processWatch = "MossX64"

# Check if the folder exists
if (-Not (Test-Path -Path $extractPath))
{
	# Create the folder
	New-Item -ItemType Directory -Path $extractPath -Force
}

# Add the folder to Microsoft Defender exclusions
Add-MpPreference -ExclusionPath $extractPath


# Check if Moss executable already exists
$mossExists = Get-ChildItem -Path $extractPath -Filter "Moss*.exe" -Recurse -ErrorAction SilentlyContinue
if (-not $mossExists)
{
	# Download MOSS
	Write-Host "Downloading MOSS from $downloadUrl..."
	Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath
	
	# Ensure 7-Zip is installed
	$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"
	if (-not (Test-Path $sevenZipPath))
	{
		Write-Error "7-Zip is required to extract the password-protected archive. Please install it first."
		exit
	}
	
	# Extract MOSS
	Write-Host "Extracting MOSS to $extractPath..."
	Start-Process -FilePath $sevenZipPath -ArgumentList "x `"$destinationPath`" -p`"$password`" -o`"$extractPath`" -y" -Wait
	
	# Cleanup MOSS
	Remove-Item -Path $destinationPath -Force
}
else
{
	$UserPrompt = Read-Host "`n`n`Force Update MOSS Client?`nA client version is already installed.`ny/Y"
	if ($UserPrompt -eq "y")
	{
		# Download MOSS
		Write-Host "Downloading MOSS from $downloadUrl..."
		Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath
		
		# Ensure 7-Zip is installed
		$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"
		if (-not (Test-Path $sevenZipPath))
		{
			Write-Error "7-Zip is required to extract the password-protected archive. Please install it first."
			exit
		}
		
		# Extract MOSS
		Write-Host "Extracting MOSS to $extractPath..."
		Start-Process -FilePath $sevenZipPath -ArgumentList "x `"$destinationPath`" -p`"$password`" -o`"$extractPath`" -y" -Wait
		
		# Cleanup MOSS
		Remove-Item -Path $destinationPath -Force
	}
}

function Get-GameCodeFromJson
{
	param (
		[string]$JsonUrl = "https://nohope.eu/down/games.json",
		[string]$ParentPath = "$env:USERPROFILE\MOSS",
		[string]$CsvPath = "$env:USERPROFILE\MOSS\games.csv"
	)
	
	# Step 1: Download and parse JSON
	try
	{
		$jsonData = Invoke-RestMethod -Uri $JsonUrl
		$games = $jsonData.games
	}
	catch
	{
		Write-Error "Failed to download or parse JSON from $JsonUrl"
		return
	}
	
	# Step 2: Convert to CSV and save
	try
	{
		if (!(Test-Path -Path $ParentPath)) { New-Item -Path $ParentPath -ItemType Directory -Force }
		$games | Select-Object name, code | Export-Csv -Path $CsvPath -NoTypeInformation -Force
		Write-Host "CSV saved to $CsvPath"
	}
	catch
	{
		Write-Error "Failed to save CSV file"
		return
	}
	
	# Step 3: Display numbered menu
	Write-Host "`nSelect a game:"
	for ($i = 0; $i -lt $games.Count; $i++)
	{
		Write-Host "$($i + 1). $($games[$i].name)"
	}
	
	# Step 4: Get user input
	$selection = Read-Host "`nEnter the number of your choice"
	if ($selection -match '^\d+$' -and $selection -ge 1 -and $selection -le $games.Count)
	{
		$selectedGame = $games[$selection - 1]
		Write-Host "`nYou selected: $($selectedGame.name)"
		Write-Host "Game Code: $($selectedGame.code)"
		return $selectedGame.code
	}
	else
	{
		Write-Host "Invalid selection."
		return $null
	}
}

$selectedGameCode = Get-GameCodeFromJson

# Run MOSS with selected GameCode
$mossExe = Get-ChildItem -Path $extractPath -Filter "*.exe" -Recurse | Select-Object -First 1
if ($mossExe)
{
	Write-Host "`n`nLaunching MOSS with GameCode: $selectedGameCode ..."
	Start-Process -FilePath $mossExe.FullName -ArgumentList "$selectedGameCode" -Verb RunAs
	
	Write-Host "`n`nMOSS started, please collect your files when your done for submission to Admins. Files are saved to the Desktop!"
	Start-Sleep 15
	
	#Write-Host "`n`nMOSS started, please do not close this window if you want to collect your files later for submission to Admins."
	#Wait-ForMOSSAndOpenDesktop
}
else
{
	Write-Error "Moss EXE not found after extraction."
	Start-Sleep 15
}
