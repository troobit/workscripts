[CmdletBinding()]
Param(
    [String] $rgName    = 'ETS',
    [String] $rootCert  = 'RootCert',
    [String] $childCert = 'ChildCert',
    [String] $certpwd   = 'password'
)

Set-StrictMode -Version Latest

$PSDefaultParameterValues = @{ '*:Verbose' = $true }

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

wv start Create-VPNcerts

## KeyUsage of CertSign means this certificate is used to sign other certificates
## So it can be a root certificate or a subordinate root certificate

## This cert goes into LocalUser\Personal\My (Personal Certificates)
## But it has to be exported and then imported into LocalUser\Personal\Root (Trusted Root Certification Authorities)

$certRoot = New-SelfSignedCertificate -Type Custom `
    -FriendlyName      "$rgName-$rootCert $( Get-Date -Format u )" `
    -DnsName           "$rgName-$rootCert" `
    -Subject           "CN=$rgName-$rootCert" `
    -KeySpec           Signature `
    -KeyExportPolicy   Exportable `
    -HashAlgorithm     sha256 `
    -KeyLength         2048 `
    -CertStoreLocation 'Cert:\CurrentUser\My' `
    -KeyUsageProperty  Sign `
    -KeyUsage          CertSign

if( $? )
{
    wv "Successfully created certificate $rgName-$rootCert and stored it into Cert:\CurrentUser\My"
}
else
{
    throw
}

## Specifying the "Signer" below makes this second certificate a child cert
## This cert goes into LocalUser\Personal\Certificates

$certChild = New-SelfSignedCertificate -Type Custom `
    -FriendlyName      "$rgName-$childCert $( Get-Date -Format u )" `
    -DnsName           "$rgName-$childCert" `
    -Subject           "CN=$rgName-$childCert" `
    -KeySpec           Signature `
    -KeyExportPolicy   Exportable `
    -HashAlgorithm     sha256 `
    -KeyLength         2048 `
    -CertStoreLocation 'Cert:\CurrentUser\My' `
    -Signer            $certRoot `
    -TextExtension     @( '2.5.29.37={text}1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2' )

    ## 2.5.29.37 = Enhanced Key Usage
    ## 1.3.6.1.5.5.7.3.2 = Client Authentication
    ## 1.3.6.1.5.5.7.3.1 = Server Authentication

if( $? )
{
    wv "Successfully created certificate $rgName-$childCert and stored it into Cert:\CurrentUser\My"
}
else
{
    throw
}

$secure = ConvertTo-SecureString -String $certpwd -Force -AsPlainText

$null = Export-PfxCertificate -Cert $certRoot `
    -FilePath ( Join-Path $pwd ( "$rgName-$rootCert" + '.pfx' ) ) `
    -Force `
    -Password $secure

if( $? )
{
    wv "Exported $rgName-$rootCert to $( Join-Path $pwd ( "$rgName-$rootCert" + '.pfx' ) )"
}
else
{
    throw
}

$null = Export-PfxCertificate -Cert $certChild `
    -FilePath ( Join-Path $pwd ( "$rgName-$childCert" + '.pfx' ) ) `
    -Force `
    -Password $secure

if( $? )
{
    wv "Exported $rgName-$childCert to $( Join-Path $pwd ( "$rgName-$childCert" + '.pfx' ) )"
}
else
{
    throw
}
    
## this will pop an approval dialog. click "Yes"

wv "About to import $( Join-Path $pwd ( "$rgName-$rootCert" + '.pfx' ) ) to Cert:\CurrentUser\Root"
wv "Click 'Yes'"

$null = Import-PfxCertificate `
    -Password $secure `
    -CertStoreLocation Cert:\CurrentUser\Root `
    -FilePath ( Join-Path $pwd ( "$rgName-$rootCert" + '.pfx' ) ) `
    -Exportable `
    -Confirm:$false

if( $? )
{
    wv "Imported $( Join-Path $pwd ( "$rgName-$rootCert" + '.pfx' ) ) to Cert:\CurrentUser\Root"
}
else
{
    throw
}

wv 'Done'
