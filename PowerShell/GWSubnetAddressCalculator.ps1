<#
 .SYNOPSIS
    Calculates address space to use for an Azure Gateway Subnet.

 .DESCRIPTION
    Calculates address space to use for an Azure Gateway Subnet.

 .EXAMPLE
    ./GWSubnetAddressCalculator.ps1 -AddressSpace "10.0.0.0/16" -GWPrefix 24

 .PARAMETER AddressSpace
    The FULL ADDRESS SPACE for the VNet being used, in the format 10.0.0.0/16.

 .PARAMETER GWPrefix
    The GateWay Adress Prefix. How much space do you need in the GateWay? Defaults to 27.
#>

param(
 [Parameter(Mandatory=$True)]
 [string]
 $AddressSpace,

 [string]
 $GWPrefix = '27'
)

#Split and generate values as needed...
$ipaddr = $AddressSpace.split("/")[0]
# Specify the values of w.x.y.z/n for your VNet address space and g, the prefix length of your gateway subnet: 
[int]$w= [convert]::ToInt32($ipaddr.split(".")[0], 10)
[int]$x= [convert]::ToInt32($ipaddr.split(".")[1], 10)
[int]$y= [convert]::ToInt32($ipaddr.split(".")[2], 10)
[int]$z= [convert]::ToInt32($ipaddr.split(".")[3], 10)
[int]$n= [convert]::ToInt32($AddressSpace.split("/")[1], 10)
[int]$g= [convert]::ToInt32($GWPrefix, 10)
# Calculate 
$wOctet = 16777216 
$xOctet = 65536 
$yOctet = 256 
[long]$D = $w * $wOctet + $x * $xOctet + $y * $yOctet + $z; 
for ($i = $n + 1; $i -lt $g + 1; $i++) 
{ 
$D = $D + [math]::pow(2, 32 - $i) 
} 
$w2 = [math]::floor($D / $wOctet) 
$x2 = [math]::floor( ($D - $w2 * $wOctet) / $xOctet ) 
$y2 = [math]::floor( ($D - $w2 * $wOctet - $x2 * $xOctet) / $yOctet ) 
$z2 = $D - $w2 * $wOctet - $x2 * $xOctet - $y2 * $yOctet 
# Display the result 
$dx= [string]$w2 + "." + [string]$x2 + "." + [string]$y2 + "." + [string]$z2 + "/" + [string]$g 
Write-Host "Your gateway address prefix is: " $dx
Write-Host "(it's also in your clipboard. Just it CTRL+V!)"