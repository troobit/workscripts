Param(
	[String] $forestName,
	[String] $server,
	[String] $user,
	[String] $password
)

	Set-StrictMode -Version Latest

	## created 2015-11-09
	## 2015-11-16 - Moved from using SCregEdit.wsf (it wasn't reliable) to directly editing the registry (very reliable)
	##		Made Configure-myEthernet a function and refactored appropriately
	## 2016-02-23 - Improved Write-Host and Write-Output output
	##		Moved Start-Transcript to caller, due to PS v4 bug
	## 2016-02-27 - Added log to file
	## 2018-01-17 - Changed name of log to $env:Temp/Startup-Server.txt
	## 2018-01-17 - Changed timer/wlog/wv to match Startup-DC.ps1
	## 2018-01-17 - Removed -Restart from Add-Computer, removed shutdown.exe/Restart-Computer - caller should Restart-AzureRmVm
	## 2018-01-18 - added Set-StrictMode -Version Latest
	## 2018-01-18 - now log to c:\temp\Startup-Server.txt' as the script doesn't run under a user context (so $env:Temp isnt valid)

	[String] $tempFolder  = 'c:\temp'
	[String] $logfileName = ( Join-Path $tempFolder 'Startup-Server.txt' )
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
		Write-Host   "h: $str"
	}

	function Set-myEthernetParameters
	{
		Param(
			$interfaceAlias
		)

		wv "*** Enter Configure-myEthernet, interfaceAlias='$interfaceAlias'"

		Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses $myFirstDC
		wv "Set-myEthernetParameters: Set DnsClientServerAddress interface '$interfaceAlias'"

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
	wv 'Startup-Server: start'
	wv "Startup-Server: server '$server' forest '$forestname' user '$user' password '$password'"

	## update executionpolicy
	Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Confirm:$false
	wv 'Startup-Server: ExecutionPolicy set to Unrestricted'

	if( $isFirstDC )
	{
		## Configure the time service for the forest's first DC.
		## As of Windows Server 2012 R2, equivalent PowerShell cmdlets 
		## do not exist.

		w32tm.exe /register
		w32tm.exe /config /manualpeerlist:pool.ntp.org /reliable:yes
		w32tm.exe /config /update
		w32tm.exe /resync /rediscover
		wv 'Startup-Server: Windows Time configured'
	}

	Clear-EventLog -LogName System -Confirm:$false
	wv 'Startup-Server: System event log cleared'

	Set-TimeZone $tzName -Confirm:$false

	## Install the telnet-client. It is a great debugging tool.
	## Using dism.exe works for both Windows client and Windows server.

	dism.exe /Online /Enable-Feature /FeatureName:TelnetClient | Out-Null
	wv 'Startup-Server: Installed the telnet-client'

	## enable remote desktop for administrators
	Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
	## enable the Remote Desktop rules in the firewall
	Set-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True  ### this is NOT a bool
	wv 'Startup-Server: Enabled the TS admin console and firewall rules'

	## two settings control NLA/CredSSP - reset them both

	## you can use CIM if you want. Easier to directly write to the registry IMO
	## Get-CimInstance -Class Win32_TSGeneralSetting -Namespace ROOT\CimV2\TerminalServices | Select TerminalName,UserAuth*,Security*
	## Invoke-CimMethod <Class&Namespace> -MethodName SetUserAuthenticationRequired -Arguments @{ UserAuthenticationRequired = 0 }
	## Invoke-CimMethod <Class&Namespace> -MethodName SetUserSecurityLayer          -Arguments @{ SecurityLayer              = 0 }

	Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 0
	Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name SecurityLayer      -Value 0
	wv 'Startup-Server: disabled NLA/CredSSP'

	## enable remote management
	Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent' -Name EnableRemoteMgmt -Value 1
	wv 'Startup-Server: enabled remote management'

	## disable Automatic Windows Update -- it can cause us serious issues during Create/Configure
	Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name NoAutoUpdate -Value 1
	wv 'Startup-Server: disable Windows auto-update'

	## configure ethernet interfaces
	$interfaces = ( Get-NetIpInterface | Where-Object `
		{ $_.AddressFamily -eq "IPv4" -and $_.NlMtu -eq 1500 } ).InterfaceAlias
	wv 'Startup-Server: interface(s) acquired'

	## there should only be a single interface. but protect ourselves...
	if( $interfaces -is [Array] )
	{
		wv "Startup-Server: There are $( $interfaces.Count ) interfaces"
		foreach( $ia in $interfaces )
		{
			Set-myEthernetParameters $ia
		}
	}
	else
	{
		wv 'Startup-Server: There is one interface'
		Set-myEthernetParameters $interfaces
	}

	##
	## above this point, Startup-DC and Startup-Server should be identical!!!
	##

	## Join the domain
	## secureStrings and credentials are not easily portable between computers
	$netbios = if( ( $i = $forestName.IndexOf( '.' ) ) -gt 0 ) { $forestName.SubString( 0, $i ) } else { $forestName }
	$user = $netbios + '\' + $user
	$sec  = ConvertTo-SecureString -String $password -AsPlainText -Force
	$cred = New-Object System.Management.Automation.PSCredential( $user, $sec )
	wv "Startup-Server: Created pscredential for user '$user' passsword '$password'"

	Start-Sleep -Seconds 2
	$count = 0
	$attemptLimit = 5
	while( $count -lt $attemptLimit )
	{
		$count++

		$error.Clear()
		Add-Computer `
			-DomainName $netbios `
			-Server $server `
			-Credential $cred `
			-Force `
			-ErrorAction SilentlyContinue
		if( $? )
		{
			wv "Startup-Server: Join domain '$netbios' success"
			break
		}

		wv "Startup-Server: Join domain '$netbios' failed. Error: $( $error[0].ToString() )"
		Start-Sleep -Seconds 30
	}

	if( $count -gt 0 ) 
	{
		wv "Startup-Server: Executed Add-Computer (to join domain $netbios) $count time(s)"
		if( $count -ge $attemptLimit )
		{
			wv "Could not join domain $netbios. Returning failure."
			exit 1
		}
	}

	exit 0
