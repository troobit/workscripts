function Prompt
{
    #$mywd = (Get-Location).Path
    #$mywd = $mywd.Replace( $HOME, '~' )
    # Uncomment commented lines to allow prompt to include current working directory.
    # It's a bit dumb - given you can use get-location or pwd at any time.
    Write-Host "VS-Code" -NoNewline -ForegroundColor Blue
    #Write-Host (" " + $mywd + " ") -NoNewline -ForegroundColor DarkGreen
    Write-Host "|:>" -NoNewline -ForegroundColor Cyan
    return " "
}