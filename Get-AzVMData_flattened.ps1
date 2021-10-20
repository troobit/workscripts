function Get-AzVMData() {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        $subscriptions,

        [Parameter(Mandatory=$false, Positional=1, ParameterSetName="ResourceGroupName")]
        [string]$rg
    )
    $vms = @() #Create empty object array to add the data amalgam to   
    foreach ($sub in $subscriptions){
        try {
            Set-AzContext -Subscription $sub | Out-Null
        } catch {
            Write-Host "Unable to set context for $($sub.Name) subscription"
            Write-Host $_.Error
        }
        Write-Host "----`nCollecting VM data for subscription: $($sub.Name)`n----"
        $subname = $sub.Name
        Write-Host " - Define VM's to collect data from"
        $vmsRaw = @() #Somewhere to put data that's not processed yet
        if ($rg){
            $vmsRaw = Get-AzVM -ResourceGroupName $rg #Maybe look at making an option for lists
            $vmCount = $vmsRaw.Count
        } else {
            $vmsRaw = Get-AzVM
            $vmCount = $vmsRaw.Count
        }
        Write-Host " - Count of VM's to collect from $($sub.Name):$($rg): $vmCount"
        Write-Progress -Activity "Querying Azure resources...`n$($sub.Name):$($rg):" -Status "Started"
        foreach ($vm in $vmsRaw){
            $n = [array]::IndexOf($vmsRaw,$vm)
            $progress = $n/$vmCount * 100
            Write-Progress -Activity "Querying Azure resources...`n$($sub.Name):$($rg):" -Status "$($vm.Name)" -PercentComplete $progress
            #What data do we want to collect for use later on?
            try{
                [string]$nicid = $vm.NetworkProfile.NetworkInterfaces.Id
                $ip = (Get-AzNetworkInterface -ResourceId $nicid).IpConfigurations.PrivateIpAddress
                $name = $vm.Name
                $osType = $vm.StorageProfile.OsDisk.$osType
                $vmRG = $vm.ResourceGroupName
                $tags = $vm.$tags
            }catch{
                Write-Error -Message "Unable to collect from $($vm.Name).`nError: $_" -ErrorAction Continue
            }
            try{
                $vmObject = New-Object -TypeName PSObject -Property @{
                    name = $name;
                    rg = $vmRG;
                    ip = $ip;
                    osType = $osType;
                    subscription = $subname;
                    tags = $tags
                }
            }catch{
                Write-Error -Message "Unable to write '$($vm.Name)' data.`nError: $_" -ErrorAction Continue
            }
        }
        Write-Progress -Activity "Querying Azure resources...`n$($sub.Name):$($rg):" -Status "Returning Data" -PercentComplete 100
    }
    return $vms
}