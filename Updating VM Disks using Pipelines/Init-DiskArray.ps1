param (
    # format: comma separated list of: diskType|diskSizeGB|caching|createOption
    # ex: 'Premium_LRS|128|ReadOnly|Empty,Premium_LRS|3128|ReadOnly|Empty'
    [string] $vmDisks   
)
    
$diskArray = New-Object System.Collections.ArrayList

foreach($disk in $vmDisks.Split(',')) {
    $diskConfig = $disk.Split('|')
    [void]$diskArray.Add(
        [PSCustomObject]@{
            diskType = $diskConfig[0]
            diskSize = $diskConfig[1]
            caching = $diskConfig[2]
            createOption = $diskConfig[3]
        }
    )
}

$json = ConvertTo-Json -Compress -InputObject @($diskArray)
$json = $json -replace "`t|`n|`r","" -replace '"',@"
\"
"@

return $json