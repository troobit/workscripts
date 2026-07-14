[CmdletBinding()]
Param(
    [String] $rgName     = 'rgVM',
    [String] $vmName     = 'vm',
    [String] $location   = 'eastus2',
    [String] $scriptName = 'DC-Deploy-Script',
    [String] $fileName   = 'Startup-DC.ps1',
    [String] $forestName = 'env1.local',
    [String] $dsrmPass   = 'P1on33r.Salt',
    [Switch] $restart    = $false
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

function Get-myStorageAccountName
{
    Param(
        [string] $rgName
    )

    $storageAccounts = Get-AzureRmStorageAccount -ResourceGroupName $rgName -ErrorAction SilentlyContinue
    if( !$? -or $null -eq $storageAccounts )
    {
        wv could not get storage group for resource group $rgName
        wv $error[0]
        throw
    }

    if( $storageAccounts -is [Array] )
    {
        $sa = $storageAccounts[ 0 ] #arbitrary choice
    }
    else 
    {
        $sa = $storageAccounts
    }

    $global:storageAccount = $sa

    return $sa.StorageAccountName
}

function Get-myStorageAccountKey
{
    Param(
        $rgName,
        $saName
    )

    $error.Clear()
    # there are two keys, key1 and key2. we use key1
    $saKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $rgName -Name $saName -ErrorAction SilentlyContinue
    if( !$? -or $null -eq $saKeys )
    {
        wv could not obtain storage account keys for storageAccount $saName in rg $rgName
        wv $error[ 0 ]
        throw
    }

    $global:storageAccountKeys = $saKeys

    return $saKeys[ 0 ].Value
}

function New-myStorageContainer
{
    Param(
        $containerName,
        $containerContext
    )

    $error.Clear()
    $result = Get-AzureStorageContainer -Name $containerName -Context $containerContext -ErrorAction SilentlyContinue
    if( $? -and $null -ne $result )
    {
        wv container $containerName already exists
        return $containerName
    }

    $error.Clear()
    $container = New-AzureStorageContainer -Name $containerName -Context $containerContext
    if( $null -eq $container )
    {
        wv could not create storage container named $containerName
        wv $error[ 0 ]
        throw
    }

    return $container
}

##
## Main
##

$error.Clear()

$saName = Get-myStorageAccountName $rgName
$saKey  = Get-myStorageAccountKey  $rgName $saName

wv saName $saName
wv saKey  $saKey

$containerName  = 'scripts'
$error.Clear()
$storageContext = New-AzureStorageContext -StorageAccountName $saName -StorageAccountKey $saKey
if( $null -eq $storageContext )
{
    wv could not create storage context in storageaccountname $saName
    throw
}

$error.Clear()
$storageContainer = New-myStorageContainer $containerName $storageContext
if( $null -eq $storageContainer )
{
    wv could not create container $containerName
    throw
}

## remove the script extension, if it already exists
$error.Clear()
$scriptExt = Get-AzureRmVMCustomScriptExtension -ResourceGroupName $rgName -VMName $vmName -Name $scriptName -ErrorAction SilentlyContinue
if( $? -and $null -ne $scriptExt )
{
    Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $rgName -VMName $vmName -Name $scriptName -Force -Confirm:$false
}

## finally, upload the file to the container in the storage account blob
## -Force is in case the file already exists in the blob
$baseFileName = Split-Path -Leaf -Path $fileName
$error.Clear()
Set-AzureStorageBlobContent -Container $containerName -File $fileName -Blob $baseFileName -Context $storagecontext -Force

$error.Clear()
$global:customScript = Set-AzureRmVMCustomScriptExtension `
    -ResourceGroupName $rgName `
    -Location $location `
    -VMName $vmName `
    -Name $scriptName `
    -StorageAccountName $saName `
    -StorageAccountKey $saKey `
    -ContainerName $containerName `
    -FileName $baseFileName `
    -Run $baseFileName `
    -Argument "$forestName $dsrmPass" `
    -ErrorAction SilentlyContinue

## don't restart if prior command failed
if( $? )
{
    wv "Set-AzureRmVMCustomScriptExtension succeeded."
    if( $restart )
    {
        Restart-AzureRmVm -ResourceGroupName $rgName -Name $vmName -Confirm:$false
    }

    exit 0
}

wv "Set-AzureRmVMCustomScriptExtension failed, errorCount $( $error.Count )"
wv $error[ 0 ]
exit 1
