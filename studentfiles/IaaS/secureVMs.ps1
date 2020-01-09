param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String] $Alias
)

$resGrpName = $Alias + "-resgrpUS"
$keyvaultName = $Alias + "-keyvault"
$location = "West US"

# Setup key vault to support VM encryption
Set-AzKeyVaultAccessPolicy -VaultName $keyvaultName -EnabledForDiskEncryption

$KeyVault = Get-AzKeyVault -VaultName $keyvaultName -ResourceGroupName $resGrpName

# Encrypt all the VMs in the given resource group of the logged in subscription
$allVMs = Get-AzVm -ResourceGroupName $resGrpName
foreach($vm in $allVMs)
{
    Write-Host "Encrypting VM: $($vm.Name) in ResourceGroup: $($vm.ResourceGroupName) " -foregroundcolor Green;

    # Encrypt the virtual machine
    Set-AzVMDiskEncryptionExtension -ResourceGroupName $resGrpName -VMName $vm.Name -Force -DiskEncryptionKeyVaultUrl $KeyVault.VaultUri -DiskEncryptionKeyVaultId $KeyVault.ResourceId

    # Show encryption status of the VM
    #Get-AzVmDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name;
}
