Get-ChildItem | `
ForEach-Object {
    $hash = (Get-FileHash -Algorithm SHA256 $_.FullName).Hash
    $name = $_.BaseName + $_.Extension
    Write-Output $name",",$hash
    $obj = New-Object PSObject -Property @{ Name = $name; Hash = $hash }
    $obj | Select-Object Name,Hash | Export-Csv sha256_hashes.csv -Append
}

Compare-Object -ReferenceObject $old -DifferenceObject $new -Property name,hash -IncludeEqual -PassThru | `
Select-Object name,sideIndicator