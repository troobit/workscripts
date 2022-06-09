[CmdletBinding()]
Param(
	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $location = 'eastus',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $rgName = 'ETS',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $vNetNameBase = 'vnet',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $vNetCIDR = '172.16.0.0/22', # '10.0.0.0/16',
	
	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $frontendSubnetNameBase = 'frontendSubnet',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $frontendSubnetCIDR = '172.16.1.0/24', # '10.0.0.0/24',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $gatewaySubnetName = 'GatewaySubnet', ## Azure requires this precise name

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $gatewaySubnetCIDR = '172.16.3.0/24', # '10.0.2.0/24',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $backendSubnetNameBase = 'backendSubnet',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $backendSubnetCIDR = '172.16.2.0/24' # '10.0.1.0/24'
)

Set-StrictMode -Version Latest

$PSDefaultParameterValues = @{ '*:Verbose' = $true }

$vNetName           = $rgName + '-' + $vNetNameBase
$frontendSubnetName = $rgName + '-' + $frontendSubnetNameBase
$backendSubnetName  = $rgName + '-' + $backendSubnetNameBase

##
## the vNet must fit inside vNetCIDR
## the vNetCIDR may contain multiple networks/subnets
##
## by default (in this script), the vNet contains 3 subnets, all contiguous
##	frontendSubnet
##  backendSubnet
##  gatewaySubnet
##

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

wv start New-vNetwork

# RG (resource group)

$objRG = Get-AzureRmResourceGroup -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if( $? -and $null -ne $objRG )
{
	wv the resource group named $rgName already exists
}
else
{
	wv resource group $rgName does not exist
	$objRG = New-AzureRmResourceGroup -Name $rgName -Location $location -ErrorAction SilentlyContinue
	if( !$? -or $null -eq $objRG )
	{
		wv could not create resource group named $rgName in location $location
		wv error $error[ 0 ]
		return
	}

	wv created a new resource group named $rgName in location $location
}

# RG network (virtual network)

[Bool] $gotvNet           = $false
[Bool] $gotFrontendSubnet = $false
[Bool] $gotGatewaySubnet  = $false
[Bool] $gotBackendSubnet  = $false

$objvNet = Get-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if( $? -and $null -ne $objvNet )
{
	wv the virtual network named $vNetName for resource group $rgName already exists
	$gotvNet = $true
	
	$objFrontendSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $frontendSubnetName -VirtualNetwork $objvNet -ErrorAction SilentlyContinue
	if( $? -and $null -ne $objFrontendSubnet )
	{
		wv the subnet named $frontendSubnetName for virtual network $vNetName already exists
		
		$gotFrontendSubnet = $true
	}

	$objGatewaySubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $gatewaySubnetName -VirtualNetwork $objvNet -ErrorAction SilentlyContinue
	if( $? -and $null -ne $objGatewaySubnet )
	{
		wv the subnet named $gatewaySubnetName for virtual network $vNetName already exists
		
		$gotGatewaySubnet = $true
	}

	$objBackendSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -VirtualNetwork $objvNet -ErrorAction SilentlyContinue
	if( $? -and $null -ne $objBackendSubnet )
	{
		wv the subnet named $backendSubnetName for virtual network $vNetName already exists
		
		$gotBackendSubnet = $true
	}
}

if( -not $gotFrontendSubnet )
{
	wv did not find subnet named $frontendSubnetName in virtual network $vNetName
	$objFrontendSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $frontendSubnetName -AddressPrefix $frontendSubnetCIDR -ErrorAction SilentlyContinue
	if( !$? -or $null -eq $objFrontendSubnet )
	{
		wv could not create subnet object $frontendSubnetName with address prefix $frontendSubnetCIDR
		wv error $error[ 0 ]
		return ############
	}
	wv created subnet object named $frontendSubnetName with address prefix $frontendSubnetCIDR
}

if( -not $gotGatewaySubnet )
{
	wv did not find subnet named $gatewaySubnetName in virtual network $vNetName
	$objGatewaySubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $gatewaySubnetName -AddressPrefix $gatewaySubnetCIDR -ErrorAction SilentlyContinue
	if( !$? -or $null -eq $objGatewaySubnet )
	{
		wv could not create subnet object $gatewaySubnetName with address prefix $gatewaySubnetCIDR
		wv error $error[ 0 ]
		return ############
	}
	wv created subnet object named $gatewaySubnetName with address prefix $gatewaySubnetCIDR
}

if( -not $gotBackendSubnet )
{
	wv did not find subnet named $backendSubnetName in virtual network $vNetName
	$objBackendSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -AddressPrefix $backendSubnetCIDR -ErrorAction SilentlyContinue
	if( !$? -or $null -eq $objBackendSubnet )
	{
		wv could not create subnet object $backendSubnetName with address prefix $backendSubnetCIDR
		wv error $error[ 0 ]
		return ############
	}
	wv created subnet object named $backendSubnetName with address prefix $backendSubnetCIDR
}

if( $gotvNet )
{
	if( -not $gotFrontendSubnet )
	{
		wv virtual network $vNetName exists so adding subnet $frontendSubnetName to the virtual network
		$objvNet = Add-AzureRmVirtualNetworkSubnetConfig -Name $frontendSubnetName -AddressPrefix $frontendSubnetCIDR `
			-VirtualNetwork $objvNet `
			-ErrorAction SilentlyContinue
		if( !$? -or $null -eq $objvNet )
		{
			wv could not add subnet $frontendSubnetName to virtual network $vNetName
			wv error $error[ 0 ]
			return ############
		}
		wv added subnet $frontendSubnetName to virtual network $vNetName
	}
	if( -not $gotGatewaySubnet )
	{
		wv virtual network $vNetName exists so adding subnet $gatewaySubnetName to the virtual network
		$objvNet = Add-AzureRmVirtualNetworkSubnetConfig -Name $gatewaySubnetName -AddressPrefix $gatewaySubnetCIDR `
			-VirtualNetwork $objvNet `
			-ErrorAction SilentlyContinue
		if( !$? -or $null -eq $objvNet )
		{
			wv could not add subnet $gatewaySubnetName to virtual network $vNetName
			wv error $error[ 0 ]
			return ############
		}
		wv added subnet $gatewaySubnetName to virtual network $vNetName
	}
	if( -not $gotBackendSubnet )
	{
		wv virtual network $vNetName exists so adding subnet $backendSubnetName to the virtual network
		$objvNet = Add-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -AddressPrefix $backendSubnetCIDR `
			-VirtualNetwork $objvNet `
			-ErrorAction SilentlyContinue
		if( !$? -or $null -eq $objvNet )
		{
			wv could not add subnet $backendSubnetName to virtual network $vNetName
			wv error $error[ 0 ]
			return ############
		}
		wv added subnet $backendSubnetName to virtual network $vNetName
	}
}
else
{
	wv virtual network $vNetName does not exist so creating it with subnets $frontendSubnetName and $gatewaySubnetName and $backendSubnetName as the only subnets
	$objvNet = New-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $rgName -Location $location `
		-AddressPrefix $vNetCIDR `
		-Subnet $objFrontendSubnet, $objGatewaySubnet, $objBackendSubnet `
		-ErrorAction SilentlyContinue
	if( !$? -or $null -eq $objvNet )
	{
		wv could not create virtual network $vNetName with subnets $frontendSubnetName and $gatewaySubnetName and $backendSubnetName
		wv error $error[ 0 ]
		return ############
	}
	wv created virtual network $vNetName with subnets $frontendSubnetName and $gatewaySubnetName and $backendSubnetName
}

wv Done
