Param(
	[String] $forestName,  ## e.g., 'env1.local'
	[String] $dsrmPassword ## plain text password!
)

	Set-StrictMode -Version Latest

	## 2015/09/08 - add comments for major areas of the script.
	## 2015/09/08 - renamed script to HelperScripts\Startup-DC.ps1
	## 2015/11/03 - added Clear-EventLog for System log
	## 2015/11/04 - Added the scregedit.wsf block and install the telnet client
	## 2015-11-05 - Set DNS server on all ethernet interfaces
	## 2015-11-21 - Merged changes from HelperScripts\Configure-Server.ps1
	## 2018-01-17 - Changed timer from "( Get-Date ).ToLongTimeString()" to "Get-Date -Format u"
    ## 2018-01-17 - removed reboot at end. caller should Restart-AzureRmVm after the custom script extension has returned.
	## 2018-01-17 - Set-Timezone 'Eastern Standard Time' -Confirm:$false
	## 2018-01-17 - added logging to $env:WinDir\Startup-DC.txt
	## 2018-01-17 - moved logging to c:\temp\Startup-DC.txt

	## NOTE: this file should be kept in sync with Startup-Server.ps1 for 
	## the non-ADDS portions of server configuration

	[String] $tempFolder  = 'c:\temp'
	[String] $logFileName = ( Join-Path $tempFolder 'Startup-DC.txt' )
	[String] $myFirstDC   = '10.0.0.4'
	[Bool]   $isFirstDC   = $false
	[String] $tzName      = 'Eastern Standard Time'

	function timer
	{
		Get-Date -Format u
	}

	function wlog
	{
		Param(
			[string] $str
		)

		$str | Out-File -FilePath $logFileName -Encoding ascii -Append
	}

	function wv
	{
		$str = timer
		$str += ' ' + ( $args -join ' ' )

		wlog $str
		## Write-Output "o: $str"
		## Write-Host   "h: $str"
	}

	function Set-myEthernetParameters
	{
		Param(
			$interfaceAlias
		)

		wv "*** Enter Configure-myEthernet, interfaceAlias='$interfaceAlias'"

		## don't do this on the DC - it'll automatically map to 127.0.0.1
		## Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses $myFirstDC
		## wv "Set-myEthernetParameters: Set DnsClientServerAddress interface '$interfaceAlias'"

		## the below disables "Automatic Configuration" including APIPA
		## I am not aware of any way to do this in PowerShell --- Now we can!
		## netsh.exe Interface IPv4 Set Interface "$interfaceAlias" DADTransmits=0 Store=Persistent
		## wv 'netsh.exe set'

		## we actually do not want DHCP screwing around with us - instead of restarting the service, disable the service
		## Restart-Service 'DHCP Client' -Force
		## wv 'DHCP Client restarted'

		## Stop-Service 'DHCP Client' -Force -Confirm:$false
		## Set-Service  'DHCP Client' -StartupType Disabled
		## wv "'DHCP Client' service has been stopped and disabled"

		## restarting the interface is no longer necessary
		## Restart-NetAdapter $interfaceAlias -Confirm:$false
		## wv 'interface restarted'

		Set-NetIPInterface -InterfaceAlias $interfaceAlias -DadTransmits 0
		wv "Set-myEthernetParameters: Disabled Autoconfiguration on '$interfaceAlias' (set DadTransmits = 0)"

		Start-Sleep -Seconds 5
		wv 'Set-myEthernetParameters: 5 second delay complete'

		wv '*** Exit Set-myEthernetParameters'
	}

	## Creating a transcript allows us to know exactly what happens during
	## the execution of this PowerShell script.
	if( -not ( Test-Path -Path $tempFolder -PathType Container ) )
	{
		mkdir $tempFolder | Out-Null
	}

	$error.Clear()
	wv 'StartUp-DC: started'
	wv "Startup-DC: forestName '$forestName' dsrmPassword '$dsrmPassword'"

	Clear-EventLog -LogName System -Confirm:$false
	wv 'Startup-DC: System event log cleared'

	## Ensure that other PowerShell scripts can be executed.
	##
	## Azure executes this particular script with "-ExecutionPolicy Bypass",
	## but that does not apply to PowerShell scripts executed at a later time.
	Set-ExecutionPolicy Unrestricted -Confirm:$false -Force
	wv 'Startup-DC: ExecutionPolicy changed to Unrestricted'

	if( $isFirstDC )
	{
		## Configure the time service for the forest's first DC.
		## As of Windows Server 2012 R2, equivalent PowerShell cmdlets 
		## do not exist.

		w32tm.exe /register
		w32tm.exe /config /manualpeerlist:pool.ntp.org /reliable:yes
		w32tm.exe /config /update
		w32tm.exe /resync /rediscover
		wv 'Startup-DC: Windows Time configured'
	}

	Set-TimeZone $tzName -Confirm:$false

	## Install the telnet-client. It is a great debugging tool.
	## Using dism.exe works for both Windows client and Windows server.

	dism.exe /Online /Enable-Feature /FeatureName:TelnetClient | Out-Null
	wv 'Startup-DC: Telnet client installed'

	## enable remote desktop for administrators
	Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
	## enable the Remote Desktop rules in the firewall
	Set-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True  ### this is NOT a bool
	wv 'Startup-DC: Enabled the TS admin console and firewall rules'

	## two settings control NLA/CredSSP - reset them both

	## you can use CIM if you want. Easier to directly write to the registry IMO
	## Get-CimInstance -Class Win32_TSGeneralSetting -Namespace ROOT\CimV2\TerminalServices | Select TerminalName,UserAuth*,Security*
	## Invoke-CimMethod <Class&Namespace> -MethodName SetUserAuthenticationRequired -Arguments @{ UserAuthenticationRequired = 0 }
	## Invoke-CimMethod <Class&Namespace> -MethodName SetUserSecurityLayer          -Arguments @{ SecurityLayer              = 0 }

	Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 0
	Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name SecurityLayer      -Value 0
	wv 'Startup-DC: disabled NLA/CredSSP'

	## enable remote management
	Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent' -Name EnableRemoteMgmt -Value 1
	wv 'Startup-DC: enabled remote management'

	## disable Automatic Windows Update -- it can cause us serious issues during Create/Configure
	Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name NoAutoUpdate -Value 1
	wv 'Startup-DC: disable Windows auto-update'

	## configure ethernet interfaces
	$interfaces = ( Get-NetIpInterface | Where-Object `
		{ $_.AddressFamily -eq "IPv4" -and $_.NlMtu -eq 1500 } ).InterfaceAlias
	wv 'Startup-DC: interface(s) acquired'

	## there should only be a single interface. but protect ourselves...
	if( $interfaces -is [Array] )
	{
		wv "Startup-DC: There are $( $interfaces.Count ) interfaces"
		foreach( $ia in $interfaces )
		{
			Set-myEthernetParameters $ia
		}
	}
	else
	{
		wv 'Startup-DC: There is one interface'
		Set-myEthernetParameters $interfaces
	}

	##
	## above this point, Startup-DC and Startup-Server should be identical!!!
	##

	$error.Clear()
	Install-WindowsFeature `
		-Name AD-Domain-Services `
		-IncludeManagementTools `
		-ErrorAction SilentlyContinue | Out-Null
	if( !$? )
	{
		wv Install-WindowsFeature failed
		wv $error[ 0 ]
		exit 1
	}

	wv 'Startup-DC: AD-Domain-Services has been installed'

	$netbios = if( ( $i = $forestName.IndexOf( '.' ) ) -gt 0 ) { $forestName.SubString( 0, $i ) } else { $forestName }

	$error.Clear()
	$password = ConvertTo-SecureString $dsrmPassword -AsPlainText -Force -ErrorAction SilentlyContinue
	if( !$? )
	{
		wv ConvertTo-SecureString failed
		wv $error[ 0 ]
		exit 1
	}

	$error.Clear()
	Install-ADDSForest `
		-DomainName $forestName `
		-DomainNetbiosName $netbios `
		-InstallDns `
		-SafeModeAdministratorPassword $password `
		-Force `
		-ErrorAction SilentlyContinue `
		-WarningAction SilentlyContinue
	if( !$? )
	{
		wv Install-ADDSForest failed
		wv $error[ 0 ]
		exit 1
	}

	wv "Startup-DC: Install-ADDSForest has completed (errorcount = $( $error.Count ))"
	wv 'Startup-DC: complete.'
	## relax for a little while...
	Start-Sleep -Seconds 30

	exit 0
