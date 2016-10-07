###########################################################################
############### Remove RavenDB Abandonned Indexes #########################
#--------------------------------------------------------------------------
# Example of call: 
#   > .\RavenDB-RemoveAbandonnedIndexes.ps1 -testRun -server "http://localhost:8080"
# Result: 
#   Start the process in test run to show what will be deleted from the specified RavenDB URL
# Tested on:
#   RavenDB 2.5
###########################################################################
[CmdletBinding()]
Param(
    # Test
    [Parameter(Mandatory=$false)]
    [switch]$testRun = $false,

    # Path to azure publish settings. It can be downloaded easilly from Azure portal
    [Parameter(Mandatory=$false)]
    [string]$ravenUrl = "http://localhost:8080",
    
    # Show help
    [Parameter(Mandatory=$false)]
    [switch]$help = $false
    )

if ($help){
    Write-Host "==============================="
    Write-Host "Parameters:"
    Write-Host " -help         : This documentation"
    Write-Host " -server ""URI"" : Specify what RavenDB Server the application will call"
    Write-Host " -testRun      : Indicate if we will delete or just display what will be deleted"
    Write-Host "==============================="
    exit 0;
}

function FetchAllDb($ravenUrl){
    $currentIdx = 0
    $pageSize = 1024
    $allDbs = New-Object System.Collections.ArrayList($null)
    do {
        $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint("$ravenUrl/databases?PageSize=$pageSize&start=$currentIdx")
        $resultObj = Invoke-RestMethod -Uri "$ravenUrl/databases?PageSize=$pageSize&start=$currentIdx" -Method Get -TimeoutSec 180
        $answer = $ServicePoint.CloseConnectionGroup("")

        $allDbs.AddRange($resultObj)
        $currentIdx += $resultObj.Count
    } while ($resultObj.Count -eq $pageSize)

    return $allDbs
}

function GetStats($dbName){
        write-host $ravenUrl/databases/$dbName/stats?noCache=1503233243
        $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint("$ravenUrl/databases/$dbName/stats?noCache=1503233243")
        $result = Invoke-RestMethod -Uri "$ravenUrl/databases/$dbName/stats?noCache=1503233243" -Method Get -TimeoutSec 180
        $answer = $ServicePoint.CloseConnectionGroup("")

        return $result
}

function DeleteIndex($dbName, $indexName){
        $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint("$ravenUrl/databases/$dbName/indexes/$indexName")
        $result = Invoke-RestMethod -Uri "$ravenUrl/databases/$dbName/indexes/$indexName" -Method Delete -TimeoutSec 180
        $answer = $ServicePoint.CloseConnectionGroup("")
        
        return $result
}

function RavenDbRemoveAbandonnedIndexes($ravenUrl){
    $dbs = FetchAllDb($ravenUrl)
    $indexTypeToRemove = "Abandoned" # Noted as "priority" in raven world

    foreach($dbName in $dbs){
        $stats = GetStats($dbName)
        foreach($dbIndex in $stats.Indexes){
          $priorities = $dbIndex.Priority -split "," | foreach {$_.Trim()}
          if ($priorities -contains $indexTypeToRemove){
            write-host "Delete => $dbName - $($dbIndex.Name)"
            if ($testRun -eq $false){
                DeleteIndex($dbName, $dbIndex.Name)
            }
          }
        }
    }
}

RavenDbRemoveAbandonnedIndexes($ravenUrl)

