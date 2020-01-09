param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String] $Alias, 

    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String] $AdminUserName,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String] $AdminUserPassword,
    
    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String] $SubscriptionName
)

# here's a good example of what you should NEVER do. don't have clear-text credentials in source code. so we use 'param()' above instead
#$Alias = "dasvab"
#$AdminUserName = "demouser"
#$AdminUserPassword = "demo@Pass123"
#$SubscriptionName = "Visual Studio Enterprise"
#$SubscriptionName = "210ba3c7-85e2-4506-8f08-41f2b910c6e0"

$AdminUserSecurePassword = ConvertTo-SecureString $AdminUserPassword -AsPlainText -Force
$LocationName = "WestUS"
$ResourceGroupName = $Alias + "-resgrpUS"
$ComputerName = $Alias + "-websrv"
$VMName = $Alias + "-web-vm"
$VMSize = "Standard_B2s"

$NetworkName = $Alias + "-vnet"
$NICName = $Alias + "-web-vm-nic"
$NSGName = $Alias + "-web-vm-nsg"
$DNSNameLabel = $Alias + "-contososhuttle" # alias-contososhuttle.westus.cloudapp.azure.com
$PublicIPAddressName = $Alias + "-web-vm-ip"
$SubnetName = "Apps"
$SubnetAddressPrefix = "10.0.0.0/24"
$VnetAddressPrefix = "10.0.0.0/16"

$KeyVaultName = $Alias + "-keyvault"
$CertName = "CSEO-SSL-Cert"
$CertDomain = "CN=*.westus.cloudapp.azure.com"

Write-Host

# sign-in to the right subscription
Write-Host "Signing-in user '$Alias' to subscription '$SubscriptionName'" -NoNewline -ForegroundColor Blue -BackgroundColor Cyan
$context = Get-AzureRmContext #-ErrorAction SilentlyContinue
if(!$context.Tenant) {
    Login-AzureRmAccount;
}
Select-AzureRmSubscription -SubscriptionID $subscriptionName

# Code commented out below (like this) is there to show how you could easily script ALL the resources you use in this lab.
# In this script, we only create resources you haven't already created manually in the labs

#Write-Host "Creating resource group" -NoNewline -ForegroundColor Blue -BackgroundColor Cyan
#New-AzResourceGroup -ResourceGroupName $ResourceGroupName -Location $LocationName

#Write-Host "Creating Key Vault" -ForegroundColor Blue -BackgroundColor Cyan
#New-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroup $ResourceGroupName -Location $LocationName -EnabledForDeployment

#Write-Host; Write-Host "Generating certificate in Key Vault" -ForegroundColor Blue -BackgroundColor Cyan
#$Policy = New-AzureKeyVaultCertificatePolicy -SecretContentType "application/x-pkcs12" -SubjectName $CertDomain -IssuerName "Self" -ValidityInMonths 3 -DnsNames $Alias + "-contososhuttle.westus.cloudapp.azure.com"
#Add-AzureKeyVaultCertificate -VaultName $KeyVaultName -Name $CertName -CertificatePolicy $Policy

#Write-Host "Creating subnet" -ForegroundColor Blue -BackgroundColor Cyan
#$Subnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix

#Write-Host "Creating vnet" -ForegroundColor Blue -BackgroundColor Cyan
#$Vnet = New-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $VnetAddressPrefix -Subnet $Subnet

Write-Host; Write-Host "Creating public IP" -ForegroundColor Blue -BackgroundColor Cyan
$PIP = New-AzPublicIpAddress -Name $PublicIPAddressName -DomainNameLabel $DNSNameLabel -ResourceGroupName $ResourceGroupName -Location $LocationName -AllocationMethod Dynamic

Write-Host; Write-Host "Creating NSG firewall and rules" -ForegroundColor Blue -BackgroundColor Cyan
Write-Host "   - Creating inbound rule for HTTP/S" -ForegroundColor Blue -BackgroundColor Cyan
$nsgRuleWEB = New-AzureRmNetworkSecurityRuleConfig -Name "HTTPS-HTTP" -Protocol "Tcp" -Direction "Inbound" -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443,80 -Access Allow
Write-Host "   - Creating inbound rule for RDP" -ForegroundColor Blue -BackgroundColor Cyan
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name "RDP" -Protocol "Tcp" -Direction "Inbound" -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
Write-Host "   - Creating NSG" -ForegroundColor Blue -BackgroundColor Cyan
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $LocationName -Name $NSGName -SecurityRules $nsgRuleRDP,$nsgRuleWEB

Write-Host; Write-Host "Creating NIC" -ForegroundColor Blue -BackgroundColor Cyan
$Vnet = Get-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id -NetworkSecurityGroupId $nsg.Id

Write-Host; Write-Host "Creating admin credentials" -ForegroundColor Blue -BackgroundColor Cyan
$Credential = New-Object System.Management.Automation.PSCredential ($AdminUserName, $AdminUserSecurePassword);

Write-Host; Write-Host "Creating VM config" -ForegroundColor Blue -BackgroundColor Cyan
$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize -AssignIdentity:$SystemAssigned
Write-Host "   - Setting VM OS settings" -ForegroundColor Blue -BackgroundColor Cyan
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
Write-Host "   - Adding NIC to VM" -ForegroundColor Blue -BackgroundColor Cyan
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
Write-Host "   - Adding source/boot image to VM" -ForegroundColor Blue -BackgroundColor Cyan
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version latest
Write-Host "   - Disabling boot diagnostics" -ForegroundColor Blue -BackgroundColor Cyan
$VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable
Write-Host; Write-Host "Creating VM" -ForegroundColor Blue -BackgroundColor Cyan
New-AzVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose

Write-Host "Installing IIS and .net 4.5 extensions" -ForegroundColor Blue -BackgroundColor Cyan
Set-AzVMExtension -ResourceGroupName $ResourceGroupName -ExtensionName IIS -VMName $VMName -Publisher Microsoft.Compute -ExtensionType CustomScriptExtension -TypeHandlerVersion 1.4 `
    -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Asp-Net45,NET-Framework-Features,Web-Server -IncludeManagementTools"}' -Location $LocationName

#Write-Host "Waiting for cert to be created successfully in Key Vault" -ForegroundColor Blue -BackgroundColor Cyan
#$certStatus = Get-AzureKeyVaultCertificateOperation -VaultName $KeyVaultName -Name $CertName
#while ($certStatus.Status -ne "completed")
#{
#    Start-Sleep -seconds 1
#    $certStatus = Get-AzureKeyVaultCertificateOperation -VaultName $KeyVaultName -Name $CertName
#}

#Write-Host; Write-Host "Adding certificate to VM from Key Vault" -ForegroundColor Blue -BackgroundColor Cyan
#$certURL = (Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $CertName).id
#$vaultId = (Get-AzureRmKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName).ResourceId
#$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName
#$vm = Add-AzureRmVMSecret -VM $vm -SourceVaultId $vaultId -CertificateStore "My" -CertificateUrl $certURL
#Update-AzureRmVM -ResourceGroupName $ResourceGroupName -VM $vm

Write-Host "Creating SSL certificate and binding to website" -ForegroundColor Blue -BackgroundColor Cyan
#"fileUris":["secure-iis.ps1"],
#"fileUris":["https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/secure-iis.ps1"],
$PublicSettings = '{
"fileUris":["https://raw.githubusercontent.com/DominoX/CSEO-labs/master/secure-iis.ps1"],
"commandToExecute":"powershell -ExecutionPolicy Unrestricted -File secure-iis.ps1"
}'
Set-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -ExtensionName "IIS" -VMName $vmName -Location $LocationName -Publisher "Microsoft.Compute" -ExtensionType "CustomScriptExtension" -TypeHandlerVersion 1.8 -SettingString $PublicSettings
