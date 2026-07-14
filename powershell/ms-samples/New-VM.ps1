[CmdletBinding()]
Param(
	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $vmAdminUser = 'myadmin',
	
	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $vmAdminPlainTextPassword = 'P1on33r.Salt',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $location = 'eastus2',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $rgName = 'rgVM',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $vmName = 'vm',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $vmSize = 'Standard_DS1_v2',

	[Parameter( Mandatory = $false )]
	[ValidateSet( '2016-Datacenter', '2012-R2-Datacenter' )]
	[String] $vmOS = '2016-Datacenter',
	
	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $vNetName = 'rgVM-vnet',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $vNetCIDR = '10.0.0.0/16',
	
	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $subnetName = 'rgVM-subnet1',

	[Parameter( Mandatory = $false )]
	[ValidateNotNullOrEmpty()]
	[String] $subnetCIDR = '10.0.0.0/24',

	[Parameter( Mandatory = $false )]
	[Bool] $stopVM = $true
)

Set-StrictMode -Version Latest

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

wv start

# RG (resource group)

$objRG = Get-AzureRmResourceGroup -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if( $? -and $null -ne $objRG )
{
	wv a resource group named $rgName already exists
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

[Bool] $gotvNet   = $false
[Bool] $gotSubnet = $false

$objvNet = Get-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if( $? -and $null -ne $objvNet )
{
	wv the virtual network named $vNetName for resource group $rgName already exists
	$gotvNet = $true
	
	$objSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $objvNet -ErrorAction SilentlyContinue
	if( $? -and $null -ne $objSubnet )
	{
		wv the subnet named $subnetName for virtual network $vNetName already exists
		
		$gotSubnet = $true
	}
	## else { 'not an error, we will just create it' }
}

if( -not $gotSubnet )
{
	wv did not find subnet named $subnetName in virtual network $vNetName
	$objSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetCIDR -ErrorAction SilentlyContinue
	if( !$? -or $null -eq $objSubnet )
	{
		wv could not create subnet object $subnetName with address prefix $subnetCIDR
		wv error $error[ 0 ]
		return ############
	}
	wv created subnet object named $subnetName with address prefix $subnetCIDR
	
	if( $gotvNet )
	{
		wv virtual network $vNetName exists so adding subnet $subnetName to the virtual network
		$objvNet = Add-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetCIDR `
			-VirtualNetwork $objvNet `
			-ErrorAction SilentlyContinue
		if( !$? -or $null -eq $objvNet )
		{
			wv could not add subnet $subnetName to virtual network $vNetName
			wv error $error[ 0 ]
			return ############
		}
		wv added subnet $subnetName to virtual network $vNetName
	}
	else
	{
		wv virtual network $vNetName does not exist so creating it with subnet $subnetName as the only subnet
		$objvNet = New-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $rgName -Location $location `
			-AddressPrefix $vNetCIDR `
			-Subnet $objSubnet `
			-ErrorAction SilentlyContinue
		if( !$? -or $null -eq $objvNet )
		{
			wv could not create virtual network $vNetName with subnet $subnetName
			wv error $error[ 0 ]
			return ############
		}
		wv created virtual network $vNetName with subnet $subnetName
	}
}

# VM Network

$dnsName   = $vmName + '-etsazure'  ## $dnsName.$location.cloudapp.azure.com
$nicName   = $vmName + '-nic'
$pubIPName = $vmName + '-publicIP'

wv dnsName $dnsName
wv nicName $nicName
wv pubIPName $pubIPName

$objPubIP = New-AzureRmPublicIpAddress  -Name $pubIPName -ResourceGroupName $rgName -Location $location `
	-DomainNameLabel $dnsName `
	-AllocationMethod Dynamic `
	-ErrorAction SilentlyContinue
if( !$? -or $null -eq $objPubIP )
{
	wv could not create public IP object $pubIPName for DomainNameLabel $dnsName
	wv error $error[ 0 ]
	return ##########
}
wv created public IP object $pubIPName for DomainNameLabel $dnsName

$objNIC   = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location `
	-SubnetId $objvNet.Subnets[ 0 ].Id `
	-PublicIpAddressId $objPubIP.Id `
	-ErrorAction SilentlyContinue
if( !$? -or $null -eq $objNIC )
{
	wv could not create NIC object $nicName in subnet $subnetName for VM $vmName
	wv error $error[ 0 ]
	return ##########
}
wv created NIC object $nicName in subnet $subnetName for VM $vmName

## A storage account name must be between 3 and 24 characters and consist of lower-case letters and numbers -
## and only those. The name must also be unique. I'm not sure if the uniqueness must be Azure-wide or just
## for this location, but finding a unique name adds a lot of complexity. So, since Azure will pick a 
## storage account name for us automatically, even if it's opaque, we let it (in Azure classic services mode, 
## we had to figure this out, in Azure resource manager mode, we do not have to figure it out).
##
## if this changes, add in this line below:
## $vm = Set-AzureRmVMBootDiagnostics  -VM $vm -Enable -ResourceGroupName $rgName -StorageAccountName $storageAccountName

# Credentials for a local administrator account in the VM
$vmAdminSecurePassword  = ConvertTo-SecureString $vmAdminPlainTextPassword -AsPlainText -Force
$credential             = New-Object System.Management.Automation.PSCredential( $vmAdminUser, $vmAdminSecurePassword )

$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
$vm = Set-AzureRmVMOperatingSystem  -VM $vm -Windows -ComputerName $vmName -Credential $credential -ProvisionVMAgent ## -EnableAutoUpdate
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $objNIC.Id
$vm = Set-AzureRmVMSourceImage      -VM $vm -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Sku $vmOS -Version 'latest'
if( $null -eq $vm )
{
	wv VM configuration failed somewhere so more debug info is needed
	return ##########
}
wv VM configuration succeeded
wv calling New-AzureRmVM for VM $vmName

$objVM = New-AzureRmVM -ResourceGroupName $rgName `
	-Location $location `
	-VM $vm `
	-Verbose `
	-ErrorAction SilentlyContinue
if( !$? -or $null -eq $objVM )
{
	wv could not create new azureRmVM named $vmName
	wv error $error[ 0 ]
	return ##########
}

wv created new azureRmVm named $vmName

Get-AzureRmVm -ResourceGroupName $rgName $vmName | Format-List

if( $stopVM )
{
	wv stopping the VM
	$null = Stop-AzureRmVm -Name $vmName -ResourceGroupName $rgName -Force
	wv stop VM complete
}

# Remove-AzureRmResourceGroup -Name rgVM -Confirm:$false -Force
