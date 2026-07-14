#Variable definition
$vmname = 'OBJ-CLIENT-01'
$cred = Get-Credential
$vmsize = 'Standard_D2s_v3'
$rg = 'Objective_POC'
$location = 'AustraliaCentral'
$vnet = Get-AzVirtualNetwork -ResourceGroupName $rg

#What image SKU and VM sizes will we use?
{
  Get-AzVMImagePublisher -Location $location | Where-Object -Property PublisherName -Like *Microsoft*
  Get-AzVMImageOffer -Location $location -PublisherName 'MicrosoftWindowsDesktop' | Where-Object -Property Offer -EQ 'Windows-10' | Select-Object -Property Id
  Get-AzVMSize -Location $location | Where-Object -Property Name -Like *D2S_v3*
}

# Define the NIC so we don't have a pip assigned.
$nic = New-AzNetworkInterface -Name $vmname -ResourceGroupName $rg -Location $location -SubnetId $vnet.Subnets[2].Id
# VM Config block
 $vmconfig = New-AzVMConfig -VMName $vmname -VMSize $vmsize
 $vmconfig = Set-AzVMOperatingSystem `
  -VM $vmconfig `
  -Windows -ComputerName $vmname `
  -Credential $cred `
  -ProvisionVMAgent -EnableAutoUpdate
 $vmconfig = Add-AzVMNetworkInterface -VM $vmconfig -Id $nic.Id
 $vmconfig = Set-AzVMSourceImage -VM $vmconfig `
  -PublisherName 'MicrosoftWindowsDesktop' `
  -Offer 'Windows-10' `
  -Skus '19h1-ent' `
  -Version latest
new-azvm -ResourceGroupName $rg -Location $location -VM $vmconfig -verbose