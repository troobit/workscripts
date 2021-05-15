Get-Process | Export-Csv -LiteralPath "$(Get-Location)\compare1.txt" -Force

$obj1 = Import-Csv "$(Get-Location)\compare1.txt"

Compare-Object -ReferenceObject $obj1 -DifferenceObject $(Get-Process) -Property Name | Out-GridView

Get-ChildItem -Name .\compare1.txt | Remove-Item -Force

Get-Help Stop-Service -ShowWindow