###########################################################################
############### Stop or start Production azure slot #######################
###########################################################################
$needToConnectToAzureAccount = $false
$testRun = $true
$stopStagingSlot = $false
$subscriptionId = "YourSubscriptionId"

# Connect to the azure account
if ($needToConnectToAzureAccount -eq $true)
{
    Add-AzureAccount 
}

# Select the production subscription
Write-Host "INFO: Selecting azure subscription" -ForegroundColor Yellow
Select-AzureSubscription -SubscriptionId $subscriptionId

# Filter to get only the slots (quick query, since we don't want to query each website in a big environment)
Write-Host "INFO: Fetch all the available AzureWebsites and filter to keep only staging slot" -ForegroundColor Yellow
$message = "shutdown"
if ($stopStagingSlot -eq $true){
    $azureWS = Get-AzureWebsite | where-object -FilterScript{$_.State -eq 'Running' -and $_.Name -like '*(staging)' } | Sort-Object Name
    $message = "shutdown"
}
else {
    $azureWS = Get-AzureWebsite | where-object -FilterScript{$_.State -eq 'Stopped' -and $_.Name -like '*(staging)' } | Sort-Object Name
    $message = "started"
}

# Resume of what will be done
Write-Host "INFO: Amount of WebSite to stop: $($azureWS.Count)" -ForegroundColor Yellow

# Do work
foreach ($website In $azureWS)
{
    if ($testRun -eq $false)
    {
        if ($stopStagingSlot -eq $true){
            $result = Stop-AzureWebsite $website.Name
        }
        else {
            $result = Start-AzureWebsite $website.Name
        }
    }

    if($result)
    {
        Write-Host "- $($website.Name) did not $message successfully" -ForegroundColor Red
    }
    else
    {
        Write-host "+ $($website.Name) $message successfully" -ForegroundColor "green"
    }
}

Write-Host ""
$TextInfo = (Get-Culture).TextInfo
Write-host "INFO: $($TextInfo.ToTitleCase($message)) all staging slots action complete" -foregroundcolor "Yellow"
