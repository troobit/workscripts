#Get VM IPS and RGs

$vms = get-azvm
$nics = get-aznetworkinterface | Where-Object $null -NE VirtualMachine #skip Nics with no VM associated
$objs = @()

foreach($nic in $nics)
{
    $vm = $vms | where-object -Property Id -EQ $nic.VirtualMachine.id
    $rg = $vm.ResourceGroupName
    $ip =  $nic.IpConfigurations | select-object -ExpandProperty PrivateIpAddress
    if ($null -NE $vm.Name) {
        #Write-Output "$rg, $($vm.Name), $ip"
        $obj = New-Object -TypeName psobject -Property @{ RG=$rg; VM=$($vm.Name); IP=$ip}
        $objs += $obj
    }
}

$objs