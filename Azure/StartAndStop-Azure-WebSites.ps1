###########################################################################
############### Start or Stop websites ####################################
#--------------------------------------------------------------------------
# Example of call: 
#   > .\StartAndStop-Azure-WebSites.ps1 -testRun -stop -servers @("*(staging)") -azurePublishSettingsPath c:\\folder\publish.publishsettings
# Result: 
#   Start the process in test run to stop web app from the specified subscription in publish
#   setting files that finish with "(staging)" in their names.
###########################################################################
[CmdletBinding()]
Param(
    # Test what web application will start or stop
    [Parameter(Mandatory=$false)]
    [switch]$testRun,
    
    # Stops the web application if activated
    [Parameter(Mandatory=$false)]
    [switch]$stop,
    
    # Default (all) using wildcards
    [Parameter(Mandatory=$false)]
    [string[]]$servers = @("*"),
    
    # Path to azure publish settings. It can be downloaded easilly from Azure portal
    [Parameter(Mandatory=$true)]
    [string]$azurePublishSettingsPath,

    # Help
    [Parameter(Mandatory=$false)]
    [switch]$help,

    # Default execution
    [Parameter(Mandatory=$false)]
    [switch]$default
)

if ($default){
    $testRun = $true;
    $stop = $true;
    $servers = @("*");
    $azurePublishSettingsPath = "C:\\folder\\credentials.publishsettings";
}

if ($help){
    Write-Host "Help..."
    exit 0;
}

# Connect to the azure account
if ($azurePublishSettingsPath) {# Have a value
    $subInfo = Import-AzurePublishSettingsFile $azurePublishSettingsPath
} else {
    write-host "Error: Please fill the azurePublishSettingsPath variable." -foregroundcolor Red
    exit 1;
}

if ($testRun -eq $true) {
    write-host "DEBUG: TestRun active. Be aware that nothing will be started or stopped." -ForegroundColor Cyan 
}
    
# Select the subscription and set it as Default
Write-host "INFO: Selecting azure subscription" -ForegroundColor Yellow
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
