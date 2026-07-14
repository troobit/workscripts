function Get-DUEPassword {
    param (
        # Source Storage Account Name
        [Parameter(Mandatory=$false)]
        [switch]$VTO,

        [Parameter(Mandatory = $true)]
        [string]$vm
        )

    $kv_vto = "fndotscacac120210410kv"
    $kv_vtp = "fndptscacac120210413kv"
    $kv = $kv_vtp
    if ($VTO){
        $kv = $kv_vto
    }

    $result = (Get-AzKeyVaultSecret -VaultName $kv -Name "srv-$vm-admpwd").SecretValueText
    return $result
}