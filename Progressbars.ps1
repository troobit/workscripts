$Progress = @{
    Id = 1 #ID is used if you have multiple progress bars or more than one thing happenning.
    Activity = "Pinging IPxx"
    Status = "Total Progress: "
    CurrentOperation = 'Testing'
    PercentComplete = 0
}
for ($i = 1; $i -le 100; $i++){
    Clear-Host
    $Progress.PercentComplete = $i
    Write-Progress @Progress -
    Start-Sleep -Milliseconds 50
}

for ($i = 1; $i -le 100; $i++ )
{
    Write-Progress -Activity "Search in Progress" -Status "$i% Complete:" -PercentComplete $i;
}