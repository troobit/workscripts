Set-Location ~
function Prompt
{
    $mywd = (Get-Location).Path
    $mywd = $mywd.Replace( $HOME, '~' )
    # Uncomment commented lines to allow prompt to include current working directory.
    # It's a bit dumb - given you can use get-location or pwd at any time.
    Write-Host ("`n| " + $mywd + "\") -ForegroundColor Cyan
    Write-Host "PS" -NoNewline -ForegroundColor DarkGreen
    Write-Host "|:>" -NoNewline -ForegroundColor Green
    return " "
}

function Edit-PSProfile
{
    code $Profile
}

function Get-Colours # So you can look at the colours and edit things to your preference. Nothing fancy.
{
    [enum]::GetValues([System.ConsoleColor]) | Foreach-Object {

        Write-Host "     " -BackgroundColor $_ -NoNewline
        Write-Host (" " + $_)
    }
}


function Clean-Help #Deletes duplicates in help, and updates help. Basically so you can actually use it.
{
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseApprovedVerbs", Scope="function")]
    $h0 = Get-ChildItem -Path 'C:\Windows\System32\WindowsPowerShell\v1.0\en-US\' -Filter {*help*}
    $h1 = Get-ChildItem -Path 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\' -Recurse -File -Filter {*help*}
    $comp = Compare-Object -ReferenceObject $h0 -DifferenceObject $h1 -Property Name -IncludeEqual | Where-Object -Property sideIndicator -Match ==
    
    #Next block is conditional on there actually being duplicates. If $comp is null, no dupes. If not, sort them out!
    if ($comp){
        $h2 = foreach ($i in $comp){
            $h0 | Where-Object {$_.Name -Match $i}
            }
        foreach($file in $h2){
            $file.delete()
        }
    }
}

#### Here's where we get tricky. The following chunk of code will be for using PowerShell in conjunction with AzCopy and other CmdLets
#### None of it is guaranteed to work. It might. But it also might not.

function AzCopy
{
    param (
        # Source Storage Account Name
        [Parameter(Mandatory = $true)]
        [ValidatePattern("^[a-z0-9`]{3,24}$")]
        [string]$saName,

        # Source Storage Account Key
        [Parameter(Mandatory = $true)]
        [string]$saKey,

        # Where are the files copying to?? Need a location for that.
        [Parameter(Mandatory = $true)]
        [string]$destinationPath,
        
        #AzCopy executable path - defaults to "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe"
        [Parameter(Mandatory = $false)]
        $AzCopyPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe"
    )

    $azCopyCmd = [string]::Format("""{0}"" /source:{1} /sourcekey:""{2}"" /Dest:""{3}"" /s",$AzCopyPath, $saName, $saKey, $destinationPath);
    Write-Host "Executing the following command in cmd:";
    Write-Host $azCopyCmd;

    cmd /c $azCopyCmd
}