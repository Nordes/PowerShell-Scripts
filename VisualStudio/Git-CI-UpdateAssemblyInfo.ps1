#---------------------
# Git Version update for assembly versions
# Take the branch name + last commit revision and put it in the assembly informal version.
#---------------------
# Original idea is from : https://github.com/jeffrymorris/githook-version-example/blob/master/src/post-merge
#---------------------

# Available assembly info
$assemblyInfos = Get-ChildItem -path "./" -Recurse -Include AssemblyInfo.cs

#get the latest tag info. The 'always' flag will give you a shortened SHA1 if no tag exists.
$tag = (git describe --always).Split("-")[-1] # get only the last part of the description
$currentDate = Get-Date -Format g

# IMPORTANT! REALLY needs to be a Major.Minor.Build
#            If you try with any other string you will get compilation errors.
$version = "0.0.0" # If you want to force a version (1.0.0 is the default) 

$currentBranch = git rev-parse --abbrev-ref HEAD

Write-Host "Last commit (Tag + Commit Id): $tag"
Write-Host "Version $version $currentDate"

function UpdateAssemblyInfo($filePath, $wordToFind, $wordToReplace){
    $containsWord = (get-content $filePath) | %{$_ -match $wordToFind}

    If(-not ($containsWord -contains $true))
    {
        #Write-Host "add"
        Add-Content $filePath -Encoding UTF8 "[assembly: $wordToReplace]"
    }
    else {
        #Write-Host "update"
        (get-content $filePath) | ForEach-Object { $_ -replace $wordToFind,$wordToReplace} | Out-File -Encoding UTF8 $filePath
    }
}

foreach($assemblyInfo in $assemblyInfos){
    UpdateAssemblyInfo $assemblyInfo.FullName "AssemblyFileVersion\((.)*\)" "AssemblyFileVersion(""$version"")"
    UpdateAssemblyInfo $assemblyInfo.FullName "AssemblyVersion\((.)*\)" "AssemblyVersion(""$version"")"
    UpdateAssemblyInfo $assemblyInfo.FullName "AssemblyInformationalVersion\((.)*\)" "AssemblyInformationalVersion(""$tag $currentBranch $currentDate"")"

    Write-Host "AssemblyInfo modified: " $assemblyInfo.FullName
}

Write-Host "Total project modified : " $assemblyInfos.Count
