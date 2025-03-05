<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2025 v5.9.253
	 Created on:   	2/13/2025 3:34 PM
	 Created by:   	Skylancer
	 Organization: 	Florida State University
	 Filename:     	SU-SatWPFForm.ps1
	===========================================================================
	.DESCRIPTION
		Simple Satisfaction form for tracking areas
#>

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

# Define the WPF XAML UI
$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Satisfaction Survey" Height="200" Width="300" WindowStartupLocation="CenterScreen">
    <Grid>
        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
            <TextBlock Text="Rate your satisfaction:" FontSize="14" Margin="0,10,0,10"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <Button Name="btn1" Content="1" Width="40" Margin="5"/>
                <Button Name="btn2" Content="2" Width="40" Margin="5"/>
                <Button Name="btn3" Content="3" Width="40" Margin="5"/>
                <Button Name="btn4" Content="4" Width="40" Margin="5"/>
                <Button Name="btn5" Content="5" Width="40" Margin="5"/>
            </StackPanel>
            <TextBlock Name="txtStatus" Text="" FontSize="12" Foreground="Green" Margin="0,10,0,0"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Load XAML
$xmlReader = New-Object System.IO.StringReader $XAML
$xmlReaderObj = New-Object System.Xml.XmlTextReader $xmlReader
$Form = [Windows.Markup.XamlReader]::Load($xmlReaderObj)

# Get buttons and status text
$btn1 = $Form.FindName("btn1")
$btn2 = $Form.FindName("btn2")
$btn3 = $Form.FindName("btn3")
$btn4 = $Form.FindName("btn4")
$btn5 = $Form.FindName("btn5")
$statusText = $Form.FindName("txtStatus")

# Define CSV File Location
$Desktop = [System.Environment]::GetFolderPath('Desktop')
$Date = (Get-Date).ToString("yyyy-MM-dd")
$CSVFile = "$Desktop\Satisfaction_$Date.csv"

# Ensure the CSV has headers if new
if (!(Test-Path $CSVFile))
{
	"Timestamp,Satisfaction" | Out-File -FilePath $CSVFile -Encoding UTF8
}

# Function to handle button clicks
function Record-Satisfaction
{
	param ($satisfaction)
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	"$timestamp,$satisfaction" | Out-File -FilePath $CSVFile -Append -Encoding UTF8
	$statusText.Text = "Recorded: $satisfaction"
}

# Assign event handlers
$btn1.Add_Click({ Record-Satisfaction 1 })
$btn2.Add_Click({ Record-Satisfaction 2 })
$btn3.Add_Click({ Record-Satisfaction 3 })
$btn4.Add_Click({ Record-Satisfaction 4 })
$btn5.Add_Click({ Record-Satisfaction 5 })

# Show Form
$Form.ShowDialog()
