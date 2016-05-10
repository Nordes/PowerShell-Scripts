$ravenUrl = "http://localhost:8080"
$req = [System.Net.WebRequest]::Create("$ravenUrl/databases?PageSize=1024")

# To exclude some databases you can put the databases in a list
#   Example: @("Master", "Tasks")
[string[]] $excludedDbList = @()

# To delete some databases, you can do it here. If any is listed, we won't delete
# all the other one.
#
#   Example: @("Master", "Tasks")
[string[]] $toDeleteDbList = @()

$response = $req.GetResponse()
$reqstream = $response.GetResponseStream()

$sr = new-object System.IO.StreamReader $reqstream
$result = $sr.ReadToEnd()
$resultObj = ConvertFrom-Json $result

if ($toDeleteDbList.Count -gt 0)
{
    # Intersect and keep only those that match
    $resultObj = $resultObj | ?{$toDeleteDbList -contains $_}
}

# Send delete command to each of those databases.
foreach($db in $resultObj)
{
    if ($excludedDbList.Count -gt 0 -and $excludedDbList -contains $db)
    {
        Write-Host "Skipping : $db"
        continue;
    }

    Write-Host "Removing database : $db"
    # Hard delete
    $Url = "$ravenUrl/admin/databases/"+$db+"?hard-delete=true"
    #Write-Host "Removing database : $url"
    
    Invoke-RestMethod -Uri $Url -Method delete | Out-Null
    Start-Sleep -Seconds 1
}

write-host "==================== Finished deleting ===================="
