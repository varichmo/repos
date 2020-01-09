
###################################################################
# This script expects 4 mandatory parameters:
#	- the email address of the user who owns the Azure subscription
#	- the System ID (SID) of that user
#	- the tenant ID for that subscription
#	- the path and name of the JSON template file
###################################################################

param(
    [Parameter(Mandatory=$True)] $subscOwner,
    [Parameter(Mandatory=$True)] $subscOwnerSID,
    [Parameter(Mandatory=$True)] $tenantID,
	[Parameter(Mandatory=$True)] $templateFilePath
)

##################################################################
# These are variables used by various Azure cmdlets in this script
# We also print some of these out to the console for debugging
##################################################################

$alias = $subscOwner.Replace("@microsoft.com","")
$resourceNamesPrefix = $alias.Replace("v-", "")
$resourceNamesPrefix = $resourceNamesPrefix.Replace("t-", "")
$resourceGroupName = $resourceNamesPrefix + "-resgrpAsia"
$sqlServerName = $resourceNamesPrefix + "-paas-sqlsrv"
$storageAcctName = $resourceNamesPrefix + "storageasia"
$azureRegion = "Southeast Asia"

$startDateTime = Get-Date -UFormat "%Y%m%d-%H%M%S"
$deploymentName = "ARM_automated_deployment-" + $startDateTime

Write-Host
Write-Host "Deployment Details:"
Write-Host "   Deploy To Datacenter = $azureRegion"
Write-Host "   Resource Group Name = $resourceGroupName";
Write-Host "   SQL Server Name = $sqlServerName";
Write-Host "   Storage Account Name = $storageAcctName";
Write-Host

#############################################################
# An array of parameters that we'll send to the JSON template
#############################################################

$parameters = @{
	location = $azureRegion
	userPrefix = $resourceNamesPrefix
	adminEmailAddr = $subscOwner
	adminUserSID = $subscOwnerSID
	tenantID = $tenantID
}

##############################################################################################
# That's all the preparatory work that needs to be done. Below, we do the actual work in Azure
##############################################################################################

