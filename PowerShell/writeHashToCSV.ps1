Function WriteObjectToCSV() {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        $objectArray,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$filePath,

        [Parameter(Mandatory=$false, Position=2)]
        [string]$keepQuotes
    )
    if ($keepQuotes){
        Write-Host "Writing to $filePath"
        try{
            $objectArray | ConvertTo-Csv -NoTypeInformation -Delimeter "," | Out-File -Encoding utf8 -LiteralPath $filePath
        }catch {Write-Host "Something broke. `nError:`n$_"}
    }else {
        Write-Host "Writing $filePath (with quotes removed.`nUse the -KeepQuotes flag to retain them"
        try{
            $objectArray | ConvertTo-Csv -NoTypeInformation -Delimiter "," `
            | ForEach-Object {$_ -Replace '^"|"$|"(?=,)|(?<+,)"',''} `
            | Out-File -Encoding utf8 -LiteralPath $filePath
        }catch {Write-Host "Something broke. `nError:`n$_"}
    }
}