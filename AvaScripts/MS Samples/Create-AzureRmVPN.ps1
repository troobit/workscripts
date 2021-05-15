[CmdletBinding()]
Param(
    $rgName   = 'ETS',      ## pick something random but memorable
    $location = 'eastus',   ## pick something local - Get-AzureRmLocation | Sort-Object Location | Select-Object Location, DisplayName
    $vNetBase = 'vnet',     ## pick something random but memorable
    $certpwd  = 'password', ## password for the root cert PFX file
    $rootCert = 'RootCert'  ## as used in Create-VPNcerts and New-vNetwork
)

Set-StrictMode -Version Latest

$vNetName = $rgName + '-' + $vNetBase

$PSDefaultParameterValues = @{ '*:Verbose' = $true }

## References
## Configure a Point-to-Site connection to a VNet using native Azure certificate authentication: PowerShell
## https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-rm-ps
## Create and install VPN client configuration files for native Azure certificate authentication Point-to-Site configurations
## https://docs.microsoft.com/en-us/azure/vpn-gateway/point-to-site-vpn-client-configuration-azure-cert
## About VPN Gateway configuration settings
## https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings
## About Point-to-Site VPN
## https://docs.microsoft.com/en-us/azure/vpn-gateway/point-to-site-about
## Generate and export certificates for Point-to-Site connections using PowerShell on Windows 10 or Windows Server 2016
## (doesn't work on Server 2012 R2 [or before] or on Windows 8.1 [or before] - use makecert.exe instead)
## https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site

## Login-AzureRmAccount 
## Get-AzureRmSubscription
## Select-AzureRmSubscription -SubscriptionName "Visual Studio Premium with MSDN"

function timer
{
	Get-Date -Format u
}

function wv
{
	$str = timer
	$str += ' ' + ( $args -join ' ' )
	
	Write-Verbose $str
}

wv start Create-AzureRmVPN

## the variables below are defined in New-vNetwork
## they probably don't match those described below

## all subnets in the vNet must fit inside the defined vNet prefixes
## you can have multiple vNet prefixes
## multiple vNet prefixes are useful if you are mapping to on-premises environments, but otherwise, that just complicates life
## we use a single vNet prefix, because complicating life isn't worth the hassle when you can avoid the complication

#$vNetPrefix   = '10.0.0.0/16'

## we use a single /24 subnet, but given the vNetPrefix, up to 256 /24 subnets would be supported.
## or a larger subnet (e.g., 10.0.0.0/20) [or multiple larger subnets]

#$subnetPrefix = '10.0.0.0/24'
#$subnetName   = $rgName + '-frontendSubnet'

## the vpnClientAddressPool is NOT within the vNet
## it MUST BE outside of the vNet
## clients connecting to the Azure VPN will be allocated an IP address from this subnet
## starting at the lowest address (+1) up to the maximum address (-1) and then repeating

$vpnClientAddressPool = '172.16.201.0/24'

#$DNS          = '8.8.8.8'  ## this should be your Svr1, not google's public DNS
$gwSubName    = 'GatewaySubnet'  ## Azure requires this to be named EXACTLY 'GatewaySubnet'
$gwName       = $rgName + '-VPN-Gateway'
$gwIPconfName = $rgName + '-VPN-Config'
$gwIPName     = $rgName + '-VPN-PublicIP'
#$gwSubPrefix  = '10.0.2.0/24' ## must fit inside the vNet!!

## the filename of the root certificate to be uploaded to Azure
$rootCertName = Join-Path $pwd ( "$rgName-$rootCert" + '.pfx' )
if( Test-Path $rootCertName )
{
    wv "$rootCertName exists"
}
else
{
    wv "$rootCertName does not exist"
    throw "$rootCertName does not exist"
}

## the common name of the root certificate contained in the above file
$rootCertCN   = $rgName + '-' + $rootCert

wv "vpnClientAddressPool = $vpnClientAddressPool"
wv "gwSubName    = $gwSubName"
wv "gwName       = $gwName"
wv "gwIPconfName = $gwIPconfName"
wv "gwIPName     = $gwIPName"
wv "rgName       = $rgName"
wv "rootCertCN   = $rootCertCN"
wv "rootCertName = $rootCertName"

$result = Get-AzureRmResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if( !$? -or $null -eq $result )
{
    wv "resource group $rgName does not exist"
    throw
}

$vnet = Get-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $rgName
if( !$? )
{
    wv "virtual network $vNetName does not exist"
    throw
}

$objGatewaySubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $gwSubName -VirtualNetwork $vnet
if( !$? )
{
    wv "gateway subnet named $gwSubName does not exist"
    throw
}

$pip = Get-AzureRmPublicIpAddress -Name $gwIPName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if( $? -and $null -ne $pip )
{
    wv "public IP address $gwIPName has already been allocated"
}
else
{
    ## https://docs.microsoft.com/en-us/powershell/module/azurerm.network/new-azurermpublicipaddress
    wv "About to allocate a public IP address"
    ## The AllocationMethod MUST be Dynamic. I don't know why, but otherwise an error will be generated later,
    ## by New-AzureRmVirtualNetworkGateway.
    $pip = New-AzureRmPublicIpAddress -Name $gwIPName -ResourceGroupName $rgName -Location $location `
        -AllocationMethod Dynamic
    if( !$? )
    {
        throw
    }
    wv "Allocated a public IP address"
}

## https://docs.microsoft.com/en-us/powershell/module/azurerm.network/New-AzureRmVirtualNetworkGatewayIpConfig
wv "About to create a virtual network gateway IP config"
$ipconf = New-AzureRmVirtualNetworkGatewayIpConfig -Name $gwIPconfName `
    -Subnet $objGatewaySubnet `
    -PublicIpAddress $pip
if( !$? )
{
    wv "New-AzureRmVirtualNetworkGatewayIpConfig failed -- end time $( Get-Date -Format u )"
    throw "New-AzureRmVirtualNetworkGatewayIpConfig failed, error was $( $error[ 0 ] )"
}
wv "Created a virtual network gateway IP config"

## See
## https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site
## for using PowerShell instead of makecert.exe
## makecert.exe -r -n "CN=AzureVPNRootCert" -sr CurrentUser -pe -sky exchange -a sha256 -m 96 -len 2048 -ss My "AzureVPNRootCert.cer"
## makecert.exe -n "CN=AzureVPNClientCert"  -sr CurrentUser -pe -sky exchange -a sha256 -m 96 -len 2048 -ss My -is My -in AzureVPNRootCert

## https://docs.microsoft.com/en-us/powershell/module/azurerm.network/new-azurermvirtualnetworkgateway
$error.Clear()

wv "About to create virtual network gateway -- start time $( Get-Date -Format u )"
## this takes significant time - perhaps as much as 45 minutes...
$null = New-AzureRmVirtualNetworkGateway -Name $gwName -ResourceGroupName $rgName -Location $location `
    -IpConfigurations $ipconf `
    -EnableBgp $false `
    -GatewayType Vpn `
    -GatewaySku Basic `
    -VpnType RouteBased `
    -VpnClientProtocol SSTP, IKEv2 `
    -ErrorAction SilentlyContinue
if( !$? )
{
    wv "New-AzureRmVirtualNetworkGateway failed -- end time $( Get-Date -Format u )"
    throw "New-AzureRmVirtualNetworkGateway failed, error was $( $error[ 0 ] )"
}
wv "Created virtual network gateway -- end time $( Get-Date -Format u )"

$objGW = Get-AzureRmVirtualNetworkGateway -ResourceGroupName $rgName -Name $gwName `
    -ErrorAction SilentlyContinue
if( !$? -or $null -eq $objGW )
{
    wv "Get-AzureRmVirtualNetworkGateway failed -- end time $( Get-Date -Format u )"
    throw "Get-AzureRmVirtualNetworkGateway failed, error was $( $error[ 0 ] )"
}

## https://docs.microsoft.com/en-us/powershell/module/azurerm.network/set-azurermvirtualnetworkgateway
wv "About to set the VpnClientAddressPool on $gwName -- start time $( Get-Date -Format u )"
$error.Clear()
$null = Set-AzureRmVirtualNetworkGateway -VirtualNetworkGateway $objGW `
    -VpnClientAddressPool $vpnClientAddressPool
if( !$? )
{
    wv "failed -- end time $( Get-Date -Format u )"
    throw "failed setting vpnClientAddressPool, error was $( $error[ 0 ] )"
}
wv "VpnClientAddressPool has been set -- end time $( Get-Date -Format u )"

## https://docs.microsoft.com/en-us/powershell/module/azurerm.network/add-azurermvpnclientrootcertificate
$secure      = ConvertTo-SecureString -String $certpwd -Force -AsPlainText
$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2( $rootCertName, $secure )
$CertBase64  = [System.Convert]::ToBase64String( $certificate.RawData )

wv "About to set the VpnClientRootCertificate -- start time $( Get-Date -Format u )"
$null = Add-AzureRmVpnClientRootCertificate -ResourceGroupName $rgName `
    -VpnClientRootCertificateName $rootCertCN `
    -VirtualNetworkGatewayname $gwName `
    -PublicCertData $CertBase64
if( !$? )
{
    wv "Add-AzureRmVpnClientRootCertificate failed -- end time $( Get-Date -Format u )"
    throw "Add-AzureRmVpnClientRootCertificate failed, error was $( $error[ 0 ] )"
}
wv "VpnClientRootCertificate has been set -- end time $( Get-Date -Format u )"

## Azure work done
## now get client configuration information
## https://docs.microsoft.com/en-us/powershell/module/azurerm.network/new-azurermvpnclientconfiguration

wv "`$s = New-AzureRmVpnClientConfiguration -ResourceGroupName $rgName -Name $gwName -AuthenticationMethod EAPTLS -ProcessorArchitecture Amd64"
wv "`$s.VpnProfileSASUrl"

## $rgName   = 'ETS'
## $gwName   = $rgName + '-VPN-Gateway'

$s = New-AzureRmVpnClientConfiguration -ResourceGroupName $rgName `
    -Name $gwName `
    -AuthenticationMethod EAPTLS `
    -ProcessorArchitecture Amd64
    
Invoke-WebRequest -Method Get -Outfile .\VPN.zip -Uri $s.VpnProfileSASUrl
"Saved VPN-client installer as VPN.zip in folder $pwd"
''
"Enter the below into your browser to download the VPN-client installer elsewhere:"
$s.VpnProfileSASUrl
' '

wv Done
