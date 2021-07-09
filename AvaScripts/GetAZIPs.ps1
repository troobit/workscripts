function Get-AzVMSummary {
    $vms = get-azvm
    $nics = get-aznetworkinterface | Where-Object -Property VirtualMachine -NE $null #skip Nics with no VM associated
    $objs = @() #Create an empty array of objects to add to

    foreach($nic in $nics)
    {
        $vm = $vms | where-object -Property Id -EQ $nic.VirtualMachine.id
        $rg = $vm.ResourceGroupName
        $ip =  $nic.IpConfigurations | select-object -ExpandProperty PrivateIpAddress
        if ($null -NE $vm.Name) {
            #Create a new object with the data we want to show.
            $obj = New-Object -TypeName psobject -Property @{ RG=$rg; VM=$($vm.Name); IP=$ip; OSType=$vm.StorageProfile.OsDisk.OsType}
            $objs += $obj #Add to object array
        }
    }
    return $objs
}