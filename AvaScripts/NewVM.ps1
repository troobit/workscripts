$vmParams = @{
    ResourceGroupName = 'Ignition_2'
    Name = 'DC-2'
    Location = 'centralus'
    ImageName = 'Win2016Datacenter'
    PublicIpAddressName = 'DC-2-publicIP'
    Credential = $cred
    OpenPorts = 3389
  }
  $newVM1 = New-AzVM @vmParams