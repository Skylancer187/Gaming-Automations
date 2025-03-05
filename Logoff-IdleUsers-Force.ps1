<#
.SYNOPSIS
    Logs out inactive users.
.DESCRIPTION
    Logs out inactive users, except for specific users that
    have been manually approved and are allowed to stay logged
    in for indefinite periods of time.

    You can run this script directly on Powershell:

        C:\> .\Logoff-Inactive.ps1

    If you want the script to automatically log off without prompting
    first, run:

        C:\> .\Logoff-Inactive.ps1 -force

    If you want to run the script to see inactive users without actually
    logging them off (ie do a dry run), run:

        C:\> .Logoff-Inactive.ps1 -dry

    Note: If it complains that "execution of scripts is disabled 
    on this system", then first open up Powershell as an administrator 
    and run the following command:

        C:\> Set-ExecutionPolicy RemoteSigned

    ...and try again.

    Email mlee42@uw.edu for any further questions you might have.
.PARAMETER help
    Displays this help
.PARAMETER force
    Forces this script to automatically log off users without
    confirming first.
.PARAMETER dry
    Performs a dry run: runs this script but does not actually log off 
    users to faciliate double-checking.
#>
param (
	[switch]$help = $false,
	[switch]$force = $true,
	[switch]$dry = $false
)

# All users who have been logged out longer then the 
# below given time (in minutes) will be logged out

$INACTIVE_THRESHOLD = 60


# This is a list of all users who will NOT be logged
# out automatically, even if they're inactive.
# Make sure to add a backtick to the end of each line

$DO_NOT_LOGOUT = @(
	"adm-*"
	"mcnelson"
)


# The bulk of the code starts here -- it's safe to ignore 
# everything below this line.

# Parses the "idle" timestamp
function Parse-Idle($raw)
{
	if ($raw -notlike "*:*")
	{
		$raw = "0:" + $raw
	}
	if ($raw -notlike "*+*")
	{
		$raw = "0+" + $raw
	}
	
	$days, $rest = $raw.Split("+")
	$hours, $minutes = $rest.Split(":")
	
	$days = [int]$days
	$hours = [int]$hours
	$minutes = [int]$minutes
	
	$total = ($days * 24 + $hours) * 60 + $minutes
	$formatted = "{0,2} day(s), {1,2} hour(s), {2,2} minute(s)" -f $days, $hours, $minutes
	
	$output = [PSCustomObject]@{
		Days	  = $days
		Hours	  = $hours
		Minutes   = $minutes
		Total	  = $total
		Raw	      = $raw
		Formatted = $formatted
	}
	Write-Output $output
}

# Parses a single line of `Query user`
function Parse-Line ($line)
{
	$output = [PSCustomObject]@{
		Username  = $line[0].Trim()
		Id	      = $line[1].Trim()
		State	  = $line[2].Trim()
		IdleTime  = Parse-Idle $line[3].Trim()
		LogonTime = $line[4].Trim()
	}
	Write-Output $output
}

# Prints the header surrounded by blank lines
function Print-Header($header)
{
	Write-Output ""
	Write-Output $header
	Write-Output ""
}

# Prints all the users under the given header
function Print-Users($header, $users)
{
	Print-Header $header
	Write-Output ("    {0,-20}{1}" -f "USERNAME", "TIME INACTIVE")
	Write-Output ""
	foreach ($user in $users)
	{
		Write-Output ("    {0,-20}{1}" -f $user.Username, $user.IdleTime.Formatted)
	}
	Write-Output ""
}

# Returns $true if the user wants to halt, $false otherwise
function Confirm()
{
	$title = "Logout users:"
	$message = "Do you want to continue and log out the given users?"
	
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",
					  "Logs out the inactive users."
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No",
					 "Quits this script and do nothing."
	
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	$result = [bool]$host.ui.PromptForChoice($title, $message, $options, 0)
	Write-Output $result
}

# Start of main code
if ($help)
{
	Get-Help $MyInvocation.MyCommand.Path
}
else
{
	# Gets raw data on which users are inactive
	$rawInactive = Query user | Select-String -pattern "disc"
	
	# Parses that data
	$inactive = $rawInactive | %{ $_ -replace "\s\s+", "|" } | %{ Parse-Line $_.Split("|") }
	
	# Applies the blacklist
	$underThreshold = $inactive | ?{ $_.IdleTime.Total -le $INACTIVE_THRESHOLD }
	$overThreshold = $inactive | ?{ $_.IdleTime.Total -gt $INACTIVE_THRESHOLD }
	$toIgnore = $overThreshold | ?{ $DO_NOT_LOGOUT -contains $_.Username }
	$toLogout = $overThreshold | ?{ $DO_NOT_LOGOUT -notcontains $_.Username }
	
	# Prints diagnostic data
	if (!$force -or $dry)
	{
		Print-Users "The following users will be logged off." $toLogout
		Print-Users "The following users will be ignored because they are whitelisted." $toIgnore
		Print-Users "The following users will be ignored because they were recently active." $underThreshold
		$response = $dry -or $(Confirm)
		if ($response)
		{
			Exit
		}
		Write-Output ""
	}
	
	# Finally attempting to log out
	if (!$dry)
	{
		Print-Header "Starting logout process."
		foreach ($name in $toLogout)
		{
			Write-Output ("    Logging out " + $name.Username)
		}
		Write-Output ""
		Print-Header "Done!"
	}
}