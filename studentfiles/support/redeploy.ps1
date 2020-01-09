
#usage: redeploy <sql-ext/sql-complete/web-complete> alias

param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String]
    $runMode, 

    [Parameter(Mandatory=$True)]
    [ValidateNotNullorEmpty()]
    [String] 
    $alias
)

$subscriptionName					= "Visual Studio Enterprise"
$resourceGroupName					= $alias + "-resgrpUS"
$location							= "westUS"
$virtualMachineName					= $alias + "-sql-vm"
$virtualMachineSize					= "Standard_B2s"
$virtualMachineDiskType				= "Standard_LRS"   # slower, older disks to save money
$adminUsername						= "demouser"
$adminPassword						= "demo@Pass123"
$virtualNetworkName					= $alias + "-vnet"
$networkInterfaceName				= $virtualMachineName + "-nic"
$networkSecurityGroupName			= $virtualMachineName + "-nsg"
$subnetName							= "Data"
$sqlConnectivityType				= "Private"
$sqlPortNumber						= 1433
$sqlStorageDisksCount				= 1
$sqlStorageWorkloadType				= "GENERAL"
$sqlStorageDisksSize				= 16      # for the SQL data and logs
$sqlStorageDisksConfigurationType	= "NEW"
$sqlStorageStartingDeviceId			= 2
$sqlStorageDeploymentToken			= 12345   # a random token
$rServicesEnabled					= "false"


#******************************************************************************
# Execution begins here
#******************************************************************************

# basic user parameter validation
if ("sql-ext", "sql-complete" -notcontains $runMode) {
    Write-Host "Invalid runMode operation '$runMode'. Try again with either 'sql-ext' or 'sql-complete'" -ForegroundColor Yellow
    break
}

# setup the name of this deployment which will appear on the resource group/deployments blade
$runTimestamp = Get-Date -UFormat "%m%d_%H%M%S"
$deploymentName = "CSEO_SQL_redeploy_" + $runTimestamp

# build a parameter hash-table to send to our ARM templates
$parameters = @{}

$parameters.Add("alias", $alias)
$parameters.Add("subscriptionName", $subscriptionName)
$parameters.Add("resourceGroupName", $resourceGroupName)
$parameters.Add("location", $location);

$parameters.Add("virtualMachineName", $virtualMachineName)
$parameters.Add("virtualMachineSize", $virtualMachineSize)
$parameters.Add("virtualMachineDiskType", $virtualMachineDiskType)

$parameters.Add("adminUsername", $adminUsername)
$parameters.Add("adminPassword", $adminPassword)

$parameters.Add("virtualNetworkName", $virtualNetworkName)
$parameters.Add("networkInterfaceName", $networkInterfaceName)
$parameters.Add("networkSecurityGroupName", $networkSecurityGroupName)
$parameters.Add("subnetName", $subnetName)

$parameters.Add("sqlConnectivityType", $sqlConnectivityType)
$parameters.Add("sqlPortNumber", $sqlPortNumber)
$parameters.Add("sqlStorageDisksCount", $sqlStorageDisksCount)
$parameters.Add("sqlStorageWorkloadType", $sqlStorageWorkloadType)
$parameters.Add("sqlStorageDisksConfigurationType", $sqlStorageDisksConfigurationType)
$parameters.Add("sqlStorageDisksSize", $sqlStorageDisksSize)
$parameters.Add("sqlStorageStartingDeviceId", $sqlStorageStartingDeviceId)
$parameters.Add("sqlStorageDeploymentToken", $sqlStorageDeploymentToken)
$parameters.Add("rServicesEnabled", $rServicesEnabled)

$ErrorActionPreference = "Stop"

# Sign-in to the right subscription
Write-Host
Write-Host "Signing-in user '$alias' to subscription '$subscriptionName' to run deployment '$deploymentName' ..." -NoNewline -ForegroundColor Blue -BackgroundColor Cyan
$context = Get-AzureRmContext #-ErrorAction SilentlyContinue
if(!$context.Tenant) {
    Login-AzureRmAccount;
}
Select-AzureRmSubscription -SubscriptionID $subscriptionName

Write-Host
switch ($runMode) {
    sql-ext {
        Write-Host 'Re-deploying SQLIaaS extension only' -ForegroundColor Blue -BackgroundColor Cyan
        Set-AzureRmVMSqlServerExtension -ResourceGroupName $resourceGroupName -VMName $virtualMachineName -Name "SQLIaasExtension" -Version "2.0" -Location $location
    }

    sql-complete {
        # Register Resource Providers
        $resourceProviders = @("microsoft.compute","microsoft.storage","microsoft.network","microsoft.resources")
        if($resourceProviders.length) {
            foreach($resourceProvider in $resourceProviders) {
                Write-Host "Registering resource provider '$resourceProvider'" -ForegroundColor Blue -BackgroundColor Cyan
                Register-AzureRmResourceProvider -ProviderNamespace $resourceProvider
            }
        }

        Write-Host 'Re-deploying complete IaaS SQL VM and associated resources ...' -ForegroundColor Blue -BackgroundColor Cyan
        New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile "complete-SQLVM-template.json" -TemplateParameterObject $parameters    #-DeploymentDebugLogLevel All
    }

    web-complete {
        # Register Resource Providers
        $resourceProviders = @("microsoft.compute","microsoft.storage","microsoft.network","microsoft.resources")
        if($resourceProviders.length) {
            foreach($resourceProvider in $resourceProviders) {
                Write-Host "Registering resource provider '$resourceProvider'" -ForegroundColor Blue -BackgroundColor Cyan
                Register-AzureRmResourceProvider -ProviderNamespace $resourceProvider
            }
        }

        Write-Host 'Re-deploying complete IaaS WEB VM and associated resources ...' -ForegroundColor Blue -BackgroundColor Cyan
        New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile "complete-WEBVM-template.json" -TemplateParameterObject $parameters    #-DeploymentDebugLogLevel All
    }
}

Write-Host "Script finished. Check logs above." -ForegroundColor Blue -BackgroundColor Cyan -NoNewline
