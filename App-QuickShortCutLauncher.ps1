<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2025 v5.9.253
	 Created on:   	2/8/2025 10:22 AM
	 Created by:   	Skylancer
	 Organization: 	Florida State University
	 Filename:     	App-QuickShortCutLauncher.ps1
	===========================================================================
	.DESCRIPTION
		GGL Quick Shortcut Launcher
#>
# Define the folder containing shortcuts, allow input parameter with default
param (
	[string]$shortcutFolder = "C:\shortcuts"
)

# Get all .lnk files in the folder
$shortcuts = Get-ChildItem -Path $shortcutFolder -Filter "*.lnk"

# Check if there are any shortcuts available
if ($shortcuts.Count -eq 0)
{
	Write-Host "No shortcuts found in the specified folder." -ForegroundColor Red
	exit
}

# Display the menu
Write-Host "Select an application to launch:" -ForegroundColor Cyan
for ($i = 0; $i -lt $shortcuts.Count; $i++)
{
	Write-Host "[$($i + 1)] $($shortcuts[$i].BaseName)"
}

# Get user selection
$userInput = Read-Host "Enter the number of your selection"
$userSelection = [int]$userInput - 1

# Validate selection
if ($userSelection -lt 0 -or $userSelection -ge $shortcuts.Count)
{
	Write-Host "Invalid selection. Exiting..." -ForegroundColor Red
	exit
}

# Resolve shortcut target
$shell = New-Object -ComObject WScript.Shell
$shortcutPath = $shortcuts[$userSelection].FullName
$shortcut = $shell.CreateShortcut($shortcutPath)
$targetPath = $shortcut.TargetPath

# Execute the selected shortcut target
Start-Process -FilePath $targetPath

# Exit script
exit