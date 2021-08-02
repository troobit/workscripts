Get-ChildItem -filter "*hashes.csv" | `
ForEach-Object {

    $hash = (Get-FileHash -Algorithm SHA256 $_.FullName).Hash #drop the extra stuff
    $name = $_.Name
    
    $filename = "sha256_hashes.csv"
    #If the file already exists, we're checking the NEW hashes, so create another file.
    if (test-path -Path $filename -PathType Leaf) {
        $filename = "new_sha256_hashes.csv"
    }
    $obj = New-Object PSObject -Property @{ Name = $name; Hash = $hash } #Create an obj to avoid superfluous detail
    Write-Output $obj
    $obj | Select-Object Name,Hash | Export-Csv $filename -Append
}

Compare-Object -ReferenceObject $old -DifferenceObject $new -Property name,hash -IncludeEqual -PassThru | `
Select-Object name,sideIndicator