#requires -version 3
#
#  .SYNOPSIS
#
#  XenApp-AddNewMachinesToDeliveryGroup [-DeliveryController="localhost"] -DeliveryGroup -Count -MachinesCatalog
#
#  .DESCRIPTION
#
#  PowerShell script connects to specified delivery controller, provision specified number of virtual desktops to specified machine catalog and add them to specified delivery group. 
#
#  .EXAMPLE
#
#  1. Connect to localhost, provision 2 new machines in TCS Application Services Machines machine catalog and add them to TCS Application Services Desktops delivery group.
#
#     XenApp-AddNewMachinesToDeliveryGroup -DeliveryGroup "TCS Application Services Desktops" -Count 2 -MachinesCatalog "TCS Application Services Machines"
#
#  2. Connect to vmww4712, provision 3 new machines in TCS Application Services Machines machine catalog and add them to TCS Application Services Desktops delivery group.
#
#     XenApp-AddNewMachinesToDeliveryGroup -DeliveryController vmww4712 -DeliveryGroup "TCS Application Services Desktops" -Count 3 -MachinesCatalog "TCS Application Services Machines"
#
#_______________________________________________________
#  Start of parameters block
#
[CmdletBinding()]
Param(
#
#  Delivery Group
#
   [Parameter(Mandatory=$true)]
   [string]$DeliveryGroupName,
#
#  Delivery Controller
#
   [Parameter(Mandatory=$false)]
   [string]$DeliveryController="localhost",
#
#  Count of Machines to provision 
#
   [Parameter(Mandatory=$true)]
   [integer]$count,
#
#  Machines Catalog
#
   [Parameter(Mandatory=$true)]
   [string]$MachinesCatalogName
)
#
# End of parameters block
#
#_______________________________________________________
#
# Add Citrix PowerShell Snap-In
#
Add-PSSnapin Citrix.AdIdentity.Admin.V2
Add-PSSnapin Citrix.MachineCreation.Admin.V2
Add-PSSnapin Citrix.Broker.Admin.V2
#Getting nessesary objects
$IdentityPool = Get-AcctIdentityPool -AdminAddress $deliveryController -IdentityPoolName $MachinesCatalogName
$ProvisionScheme = Get-ProvScheme -AdminAddress $deliveryController -ProvisioningSchemeName $MachinesCatalogName
$MachinesCatalog = Get-BrokerCatalog -AdminAddress $deliveryController -Name $MachinesCatalogName
$DeliveryGroup = Get-BrokerDesktopGroup -AdminAddress $deliveryController -Name $DeliveryGroupName
#Create new machine AD accounts
New-AcctADAccount -AdminAddress $deliveryController -Count $count -IdentityPoolId $IdentityPool.IdentityPoolUid -OutVariable $result
#Loop every created account
$CreatedMachineADAccounts = $result[0].SuccessfulAccounts
foreach($CreatedMachineADAccount in $CreatedMachineADAccounts){
#Provision new VM
    New-ProvVM -AdminAddress $deliveryController -ADAccountName $CreatedMachineADAccount.ADAccountName -ProvisioningSchemeUid $ProvisionScheme.ProvisioningSchemeUid
#Create broker machine out of created VM
    $newBrokerMachine = New-BrokerMachine -AdminAddress $deliveryController -CatalogUid $MachinesCatalog.Uid -MachineName $CreatedMachineADAccount.ADAccountSid
#Initialize Personal Virtual Disk for created machine
    Start-BrokerMachinePvdImagePrepare -AdminAddress $deliveryController -InputObject $newBrokerMachine
#Add created machine to delivery group
    Add-BrokerMachine -AdminAddress $deliveryController -InputObject $newBrokerMachine -DesktopGroup $DeliveryGroup
}