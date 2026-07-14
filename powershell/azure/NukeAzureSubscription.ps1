#First... get the resource groups...
$rgs = (Get-AzResourceGroup | Select-Object -ExpandProperty resourcegroupname)

#Then - get the locks associated with them (or even simpler - just the lockIDs), and remove them.
$lockIds = ($rgs | ForEach-Object {get-azresourcelock -resourcegroupname $_ | select-object -ExpandProperty LockId})
$lockIds | ForEach-Object {Remove-AzResourceLock -LockId $_}

#Then we stop all running VMs...
$rgs | ForEach-Object {Get-AzVM $_} | Stop-AzVM -Force
#And... because there are cross references in DATA disk storages, we need to detach each data disk before it can be deleted
foreach ($rg in $rgs){
    $resources = (Get-AzResource -ResourceGroupName $rg)
    foreach($resource in $resources){
        #First - verify it's a data disk.
        if ($resource.ResourceType -ne 'Microsoft.Compute/disks'){
            Write-Host $resource.ResourceType
            break}
        $disk = (Get-AzDisk -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name)
        if ($disk.DiskState -eq 'Unattached'){
            Remove-AzDisk -ResourceGroupName $disk.ResourceGroupName -DiskName $disk.Name -Force
        }
        else {Write-Host ('Disk State:',$disk.DiskState)}
    }
    #If the RG is empty now, delete it...
    if ((Get-AzResource -ResourceGroupName $rg | Measure-Object).Count -eq 0)
    {
        Remove-AzResourceGroup -ResourceGroupName $rg -Force
    }
}
#If it's Reserved - get the ManagedBy (the VM), the VM, and remove the disk FROM the VM.

function detachDataDisk($dd)
{
    $managedBy = Get-AzResource -ResourceId $dd.ManagedBy
    $vm = Get-AzVm -ResourceGroupName $managedBy.ResourceGroupName -Name $managedBy.Name

    Remove-AzVMDataDisk -VM $vm -Name $dd.Name
    Update-AzVM -ResourceGroupName 
}
Get-AzResource -ResourceId (Get-AzDisk -DiskName 'C001FPST001-datadisk0').ManagedBy

foreach($rg in $rgs){
    $countRes = (Get-AzResource -ResourceGroupName $rg | Measure-Object | Select-Object -ExpandProperty Count)
    Write-Host ('RG Name:',$rg,'Resources count:',$countRes)
    if ($countRes -lt 150){
        Remove-AzResourceGroup -ResourceGroupName $rg -Force
    }
}