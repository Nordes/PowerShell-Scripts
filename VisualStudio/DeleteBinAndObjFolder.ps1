# This script will delete all the BIN and OBJ folders that are in this directory and in all the inner folders
# This script is useful to REALLY rebuild the solution
Get-ChildItem .\ -include bin,obj -Recurse | foreach ($_) { remove-item $_.fullname -Force -Recurse }
