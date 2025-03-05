<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2025 v5.9.253
	 Created on:   	3/4/2025 11:40 AM
	 Created by:   	Matthew Nelson
	 Organization: 	Florida State University
	 Filename:     	Mount-LocalM2Drive.ps1
	===========================================================================
	.DESCRIPTION
		GGL Mount Location Drive Script. Detects and preps drive.
#>

param
(
	[parameter(Mandatory = $false)]
	[string]$shortcutFolder = "G:\Shortcuts\Games"
)

# Function to format and set drive letter
function Format-Drive
{
	param (
		[string]$DriveLetter
	)
	
	$drive = Get-Partition | Where-Object { $_.Size -ge 512GB -and $_.DriveLetter -eq $DriveLetter -and $_.Type -eq 'Basic' -and $_.OperationalStatus -eq 'Online' -and $_.MediaType -eq 'Fixed' }
	if ($drive -eq $null)
	{
		$drive = Get-Partition | Where-Object { $_.Size -ge 512GB -and $_.DriveLetter -eq $null -and $_.Type -eq 'Basic' -and $_.OperationalStatus -eq 'Online' -and $_.MediaType -eq 'Fixed' }
		if ($drive -ne $null)
		{
			Initialize-Disk -Number $drive.DiskNumber -PartitionStyle GPT
			Get-Partition -DiskNumber $drive.DiskNumber | Remove-Partition -Confirm:$false
			New-Partition -DiskNumber $drive.DiskNumber -UseMaximumSize -AssignDriveLetter
			Format-Volume -DriveLetter $drive.DriveLetter -FileSystem NTFS -NewFileSystemLabel "Data"
			Set-Partition -DriveLetter $drive.DriveLetter -NewDriveLetter B
		}
		else
		{
			Write-Host "No suitable drive found."
			exit
		}
	}
	else
	{
		if ($drive.FileSystem -ne "NTFS")
		{
			Format-Volume -DriveLetter $drive.DriveLetter -FileSystem NTFS -NewFileSystemLabel "Data"
		}
		if ($drive.DriveLetter -ne "B")
		{
			Set-Partition -DriveLetter $drive.DriveLetter -NewDriveLetter B
		}
	}
}

# Function to detect original installation
function Check-OrgOS
{
	param (
		[string]$DriveLetter
	)
	
	# Get all fixed drives
	$drives = Get-Disk | Select-Object -Property *
	
	$orgOSDrive = $drives | Where-Object { ($_.ProvisioningType -eq "Fixed") -and ($_.BusType -ne "iSCSI") -and ($_.BusType -ne "USB") } | Select-Object -Property DiskNumber
	
	foreach ($drive in $orgOSDrive)
	{
		# Get the disk number
		$diskNumber = $drive.DiskNumber
		
		# Clear the disk (removes all data)
		Clear-Disk -Number $diskNumber -RemoveData -Confirm:$false -RemoveOEM
		
		# Initialize the disk with GPT partition style
		Initialize-Disk -Number $diskNumber -PartitionStyle GPT -Confirm:$false
		
		# Create a new partition using the maximum available size
		New-Partition -DiskNumber $diskNumber -DriveLetter $DriveLetter -UseMaximumSize | Out-Null
		
		# Format the volume with NTFS file system
		Format-Volume -DriveLetter $DriveLetter -FileSystem NTFS -NewFileSystemLabel "Data" -Confirm:$false | Out-Null
		
		Write-Host "Drive $driveLetter has been formatted successfully."
	}
}

# Function to create dynamic menu
function Show-Menu
{
	param (
		[string]$FolderPath
	)
	
	$shortcuts = Get-ChildItem -Path $FolderPath -Filter *.lnk
	$menuItems = @()
	
	foreach ($shortcut in $shortcuts)
	{
		$shell = New-Object -ComObject WScript.Shell
		$shortcutPath = $shell.CreateShortcut($shortcut.FullName).TargetPath
		$menuItems += [PSCustomObject]@{ Name = $shortcut.Name; Path = $shortcutPath }
	}
	
	$menuItems | ForEach-Object { Write-Host "$($_.Name)" }
	
	$selection = Read-Host "Select the number of the application to launch"
	$selectedItem = $menuItems[$selection - 1]
	
	if ($selectedItem -ne $null)
	{
		Start-Process $selectedItem.Path
	}
	else
	{
		Write-Host "Invalid selection."
	}
}

# Main script
Check-OrgOS -DriveLetter "B"
Format-Drive -DriveLetter "B"
Show-Menu -FolderPath "$shortcutFolder"