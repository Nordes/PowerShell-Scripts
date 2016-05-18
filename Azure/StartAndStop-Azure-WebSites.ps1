###########################################################################
############### Start or Stop websites ####################################
###########################################################################
Param(
    $testRun = $true,                                           # Set to $true if you want to only test what it will start/stop
    $stop = $true,                                              # Set to $true if you want to stop the staging slots
    $servers = @("*(staging)"),                                 # Example with wildcards to get all the staging slots
	$azurePublishSettings = "C:\\path\\server-credentials.publishsettings" # Can be downloaded easilly from Azure portal
)

# Connect to the azure account
if ($azurePublishSettings) {# Have a value
	$subInfo = Import-AzurePublishSettingsFile $azurePublishSettings
} else {
	write-host "Error: Please fill the azurePublishSettings variable." -foregroundcolor Red
	exit 1;
}

if ($testRun -eq $true) {
    write-host "DEBUG: TestRun active. Be aware that nothing will be started or stopped." -ForegroundColor Cyan 
}
	
# Select the subscription and set it as Default
Write-Host "INFO: Selecting azure subscription" -ForegroundColor Yellow
Select-AzureSubscription -SubscriptionId $subInfo.Id -Default $subInfo.Account

#
# Function to filter out all the servers we wish to have (using wildcard if we wish) and the azure websites.
#
function validateServerNameV2($websites, $servers)
{
	$result = @();
	# websites is a more complex type than an array
	foreach ($server in $servers)
	{
		$result += $websites | where-object { $_.Name -like $server }
	}
	
	return $result;
}

# Filter to get only the slots (quick query, since we don't want to query each website in a big environment)
Write-Host "INFO: Fetch all the available AzureWebsites and filter to keep only what we wish" -ForegroundColor Yellow
$message = "shutdown"
if ($stop -eq $true){
    $azureWS = Get-AzureWebsite | where-object -FilterScript{$_.State -eq 'Running' } | Sort-Object Name
    $message = "stop"
}
else {
    $azureWS = Get-AzureWebsite | where-object -FilterScript{$_.State -eq 'Stopped' } | Sort-Object Name
    $message = "start"
}

$azureWS = validateServerNameV2 $azureWS $servers

# Resume of what will be done
Write-Host "INFO: Amount of WebSite to $($message): $($azureWS.Count)" -ForegroundColor Yellow

# Do work
foreach ($website In $azureWS)
{
    $result = $null

    if ($stop -eq $true){
        Write-Host "- $($website.Name) Stopping..." -ForegroundColor White -NoNewline
        if ($testRun -eq $false)
        {      
            $result = Stop-AzureWebsite $website.Name
        }
    }
    else {
        Write-Host "+ $($website.Name) Starting..." -ForegroundColor White -NoNewline
        if ($testRun -eq $false)
        {      
            $result = Start-AzureWebsite $website.Name
        }
    }
    
    if($result)
    {
        Write-Host " Failed" -ForegroundColor Red
    }
    else
    {
        Write-host " Done" -ForegroundColor Green
    }
}

Write-Host ""
$TextInfo = (Get-Culture).TextInfo
Write-host "INFO: $($TextInfo.ToTitleCase($message)) -> Action complete" -foregroundcolor "Yellow"
